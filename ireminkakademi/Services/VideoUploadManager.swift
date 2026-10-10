import Foundation
import UIKit

/// Seçilen videoların uygulama içindeki geçici kopyaları. Orijinal dosya hiç yeniden kodlanmaz.
nonisolated enum VideoUploadStaging {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("PendingVideoUploads", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutable = dir
            try? mutable.setResourceValues(values)
        }
        return dir
    }

    static func copyIntoStaging(_ source: URL) throws -> URL {
        let ext = source.pathExtension.isEmpty ? "mov" : source.pathExtension
        let dest = directory.appendingPathComponent("\(UUID().uuidString).\(ext)")
        try FileManager.default.copyItem(at: source, to: dest)
        return dest
    }
}

/// Bunny Stream'e TUS protokolüyle doğrudan, parça parça ve kaldığı yerden devam ederek yükler.
@Observable
final class VideoUploadManager {
    static let shared = VideoUploadManager()

    enum Phase: Equatable {
        case waiting
        case uploading
        case finishing
        case failed(String)
    }

    struct Job: Codable, Identifiable {
        var id: String { videoId }
        let videoId: String
        let moduleId: String
        let title: String
        let fileName: String
        let fileSize: Int64
        var credentials: VideoUploadCredentials
        var uploadURL: URL?
    }

    private(set) var jobs: [String: Job] = [:]
    private(set) var phases: [String: Phase] = [:]
    private(set) var progress: [String: Double] = [:]

    /// Yükleme bitince sunucuya "işleniyor" bildirildi.
    @ObservationIgnored var onFinished: ((String) -> Void)?

    @ObservationIgnored private let service = LearningAdminService()
    @ObservationIgnored private let session: URLSession
    @ObservationIgnored private var running: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var backgroundTasks: [String: UIBackgroundTaskIdentifier] = [:]
    @ObservationIgnored private let chunkSize = 8 * 1024 * 1024
    @ObservationIgnored private let storeURL = VideoUploadStaging.directory.appendingPathComponent("jobs.json")

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: config)
        if let data = try? Data(contentsOf: storeURL),
           let saved = try? JSONDecoder().decode([String: Job].self, from: data) {
            jobs = saved.filter { FileManager.default.fileExists(atPath: fileURL(for: $0.value).path) }
            for id in jobs.keys { phases[id] = .waiting }
        }
    }

    var activeCount: Int { jobs.count }

    func jobs(inModule moduleId: String) -> [Job] {
        jobs.values.filter { $0.moduleId == moduleId }
    }

    /// Sunucuda video kaydı oluşturulduktan sonra çağrılır; dosya staging klasöründe olmalı.
    func enqueue(video: VideoDTO, credentials: VideoUploadCredentials, stagedFile: URL) {
        let size = (try? FileManager.default.attributesOfItem(atPath: stagedFile.path)[.size] as? NSNumber)?.int64Value ?? 0
        let job = Job(
            videoId: video.id,
            moduleId: video.moduleId,
            title: video.title,
            fileName: stagedFile.lastPathComponent,
            fileSize: size,
            credentials: credentials,
            uploadURL: nil
        )
        jobs[job.videoId] = job
        phases[job.videoId] = .waiting
        progress[job.videoId] = 0
        persist()
        start(job.videoId)
    }

    func resumeAll() {
        for id in jobs.keys where running[id] == nil { start(id) }
    }

    func retry(_ videoId: String) { start(videoId) }

    func cancel(_ videoId: String) {
        running[videoId]?.cancel()
        running[videoId] = nil
        finishJob(videoId)
    }

    private func start(_ videoId: String) {
        guard running[videoId] == nil, jobs[videoId] != nil else { return }
        phases[videoId] = .uploading
        running[videoId] = Task { [weak self] in
            await self?.run(videoId)
            self?.running[videoId] = nil
        }
    }

    private func run(_ videoId: String) async {
        backgroundTasks[videoId] = UIApplication.shared.beginBackgroundTask(withName: "video-upload") { [weak self] in
            self?.endBackgroundTask(videoId)
        }
        defer { endBackgroundTask(videoId) }

        var attempt = 0
        var credentialRefreshes = 0
        while !Task.isCancelled, jobs[videoId] != nil {
            do {
                try await upload(videoId)
                phases[videoId] = .finishing
                try await service.markUploaded(videoId: videoId)
                finishJob(videoId)
                onFinished?(videoId)
                return
            } catch is CancellationError {
                return
            } catch TUSError.credentialsExpired {
                credentialRefreshes += 1
                if credentialRefreshes <= 2, let fresh = try? await service.uploadCredentials(videoId: videoId) {
                    jobs[videoId]?.credentials = fresh
                    persist()
                    continue
                }
                phases[videoId] = .failed("Yükleme izni yenilenemedi.")
                return
            } catch TUSError.fatal(let message) {
                phases[videoId] = .failed(message)
                return
            } catch {
                attempt += 1
                guard attempt < 6 else {
                    phases[videoId] = .failed("Bağlantı sorunu. Tekrar dene.")
                    return
                }
                phases[videoId] = .uploading
                try? await Task.sleep(for: .seconds(min(30, 1 << attempt)))
            }
        }
    }

    private func endBackgroundTask(_ videoId: String) {
        guard let id = backgroundTasks.removeValue(forKey: videoId), id != .invalid else { return }
        UIApplication.shared.endBackgroundTask(id)
    }

    // MARK: - TUS

    private enum TUSError: Error {
        case credentialsExpired
        case fatal(String)
    }

    private func upload(_ videoId: String) async throws {
        guard let job = jobs[videoId] else { throw CancellationError() }
        let file = fileURL(for: job)
        guard job.fileSize > 0 else { throw TUSError.fatal("Video dosyası okunamadı.") }

        var offset: Int64 = 0
        if let existing = job.uploadURL, let remote = try await currentOffset(at: existing, job: job) {
            offset = remote
        } else {
            jobs[videoId]?.uploadURL = try await createUpload(job)
            persist()
        }
        guard let uploadURL = jobs[videoId]?.uploadURL else { throw TUSError.fatal("Yükleme başlatılamadı.") }

        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }

        while offset < job.fileSize {
            try Task.checkCancellation()
            try handle.seek(toOffset: UInt64(offset))
            guard let chunk = try handle.read(upToCount: chunkSize), !chunk.isEmpty else { break }

            var req = authorizedRequest(uploadURL, method: "PATCH", job: jobs[videoId] ?? job)
            req.setValue("application/offset+octet-stream", forHTTPHeaderField: "Content-Type")
            req.setValue(String(offset), forHTTPHeaderField: "Upload-Offset")
            let (_, response) = try await session.upload(for: req, from: chunk)
            let http = response as? HTTPURLResponse
            switch http?.statusCode ?? 0 {
            case 200, 204:
                offset = http?.value(forHTTPHeaderField: "Upload-Offset").flatMap(Int64.init) ?? offset + Int64(chunk.count)
            case 409:
                offset = try await currentOffset(at: uploadURL, job: job) ?? offset
            case 401, 403:
                throw TUSError.credentialsExpired
            case 404, 410:
                jobs[videoId]?.uploadURL = nil
                persist()
                throw URLError(.resourceUnavailable)
            default:
                throw URLError(.badServerResponse)
            }
            progress[videoId] = Double(offset) / Double(job.fileSize)
        }
    }

    private func createUpload(_ job: Job) async throws -> URL {
        guard let endpoint = URL(string: job.credentials.endpoint) else { throw TUSError.fatal("Geçersiz yükleme adresi.") }
        var req = authorizedRequest(endpoint, method: "POST", job: job)
        req.setValue(String(job.fileSize), forHTTPHeaderField: "Upload-Length")
        let ext = (job.fileName as NSString).pathExtension.lowercased()
        let filetype = ext == "mp4" || ext == "m4v" ? "video/mp4" : "video/quicktime"
        req.setValue(
            "filetype \(Data(filetype.utf8).base64EncodedString()),title \(Data(job.title.utf8).base64EncodedString())",
            forHTTPHeaderField: "Upload-Metadata"
        )
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 401 || http.statusCode == 403 { throw TUSError.credentialsExpired }
        guard http.statusCode == 201,
              let location = http.value(forHTTPHeaderField: "Location"),
              let url = URL(string: location, relativeTo: endpoint)?.absoluteURL else {
            throw URLError(.badServerResponse)
        }
        return url
    }

    /// `nil` → yükleme sunucuda yok, baştan başlanmalı.
    private func currentOffset(at url: URL, job: Job) async throws -> Int64? {
        let req = authorizedRequest(url, method: "HEAD", job: job)
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        switch http.statusCode {
        case 200, 204:
            return http.value(forHTTPHeaderField: "Upload-Offset").flatMap(Int64.init) ?? 0
        case 401, 403:
            throw TUSError.credentialsExpired
        default:
            jobs[job.videoId]?.uploadURL = nil
            return nil
        }
    }

    private func authorizedRequest(_ url: URL, method: String, job: Job) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("1.0.0", forHTTPHeaderField: "Tus-Resumable")
        req.setValue(job.credentials.signature, forHTTPHeaderField: "AuthorizationSignature")
        req.setValue(String(job.credentials.expire), forHTTPHeaderField: "AuthorizationExpire")
        req.setValue(job.credentials.videoId, forHTTPHeaderField: "VideoId")
        req.setValue(job.credentials.libraryId, forHTTPHeaderField: "LibraryId")
        return req
    }

    // MARK: - Persistence

    private func fileURL(for job: Job) -> URL {
        VideoUploadStaging.directory.appendingPathComponent(job.fileName)
    }

    private func finishJob(_ videoId: String) {
        if let job = jobs[videoId] { try? FileManager.default.removeItem(at: fileURL(for: job)) }
        jobs[videoId] = nil
        phases[videoId] = nil
        progress[videoId] = nil
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(jobs) {
            try? data.write(to: storeURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        }
    }
}
