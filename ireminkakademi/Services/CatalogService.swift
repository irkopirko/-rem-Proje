import Foundation

@Observable
final class CatalogService {
    @ObservationIgnored private let api = InkAPIClient.shared

    func fetchCatalog() async throws -> CatalogResponse {
        if APIConfiguration.usesMockBackend { return MockCatalog.sample }
        return try await api.request("/v1/modules", authorized: true)
    }

    func fetchPrograms() async throws -> [EducationProgramDTO] {
        if APIConfiguration.usesMockBackend {
            return [
                EducationProgramDTO(
                    id: "p1",
                    title: "INK AKADEMİ Eğitimi",
                    description: "Ink Akademi’nin temel eğitim programı.",
                    instructorName: "Ink Akademi Crew",
                    moduleCount: 1,
                    videoCount: 1,
                    displayIndex: 1
                )
            ]
        }
        let resp: ProgramsResponse = try await api.request("/v1/programs", authorized: true)
        return resp.programs
    }

    func fetchProgram(id: String) async throws -> ProgramDetailResponse {
        if APIConfiguration.usesMockBackend {
            return ProgramDetailResponse(program: try await fetchPrograms()[0], modules: MockCatalog.sample.modules)
        }
        return try await api.request("/v1/programs/\(id)", authorized: true)
    }

    func fetchModuleVideos(moduleId: String) async throws -> [VideoDTO] {
        if APIConfiguration.usesMockBackend { return MockCatalog.videos.filter { $0.moduleId == moduleId } }
        let resp: ModuleVideosResponse = try await api.request("/v1/modules/\(moduleId)/videos", authorized: true)
        return resp.videos
    }

    /// Kısa ömürlü, imzalı HLS adresi. Süresi dolunca yeniden istenmeli.
    func fetchPlayback(videoId: String) async throws -> PlaybackDTO {
        try await api.request("/v1/videos/\(videoId)/playback", authorized: true)
    }

    func saveProgress(videoId: String, lastPositionSeconds: Int, watchedSeconds: Int, completed: Bool) async throws {
        guard !APIConfiguration.usesMockBackend else { return }
        struct Body: Encodable { let lastPositionSeconds: Int; let watchedSeconds: Int; let completed: Bool }
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await api.request(
            "/v1/videos/\(videoId)/progress",
            method: "POST",
            body: Body(lastPositionSeconds: max(0, lastPositionSeconds), watchedSeconds: max(0, watchedSeconds), completed: completed),
            authorized: true
        )
    }

    func fetchProducts() async throws -> ProductsResponse {
        if APIConfiguration.usesMockBackend || APIConfiguration.usesLocalAuth {
            let local = try await LocalProductStore.shared.fetchAll()
            return local.categories.isEmpty ? MockCatalog.products : local
        }
        return try await api.request("/v1/products", authorized: true)
    }

    func fetchHomework() async throws -> [HomeworkAssignmentDTO] {
        if APIConfiguration.usesMockBackend || APIConfiguration.usesLocalAuth {
            let local = LocalHomeworkStore.shared.studentAssignments()
            return local.isEmpty ? MockCatalog.homework : local
        }
        let resp: HomeworkListResponse = try await api.request("/v1/homework", authorized: true)
        return resp.assignments
    }

    func fetchBadgeProgress() async throws -> BadgeProgressResponse {
        if APIConfiguration.usesMockBackend {
            return BadgeProgressResponse(totalXp: 0, level: 0, xpIntoLevel: 0, xpForNextLevel: 100, badges: [])
        }
        let progress: BadgeProgressResponse = try await api.request("/v1/badges", authorized: true)
        if progress.gamePlayedToday == true { DailyGameStore.markPlayedToday() }
        BadgeUnlockStore.shared.ingest(progress)
        return progress
    }

    func completeWeeklyGame() async throws -> BadgeProgressResponse {
        do {
            let progress: BadgeProgressResponse = try await api.request("/v1/game/weekly-complete", method: "POST", authorized: true)
            DailyGameStore.markPlayedToday()
            BadgeUnlockStore.shared.ingest(progress)
            return progress
        } catch InkAPIError.server(let message) where message.localizedCaseInsensitiveContains("bugün") {
            DailyGameStore.markPlayedToday()
            return try await fetchBadgeProgress()
        }
    }

    func submitHomework(assignmentId: String, files: [HomeworkPickedFile], onProgress: ((Int) -> Void)? = nil) async throws {
        guard !APIConfiguration.usesMockBackend else { return }
        for (index, file) in files.enumerated() {
            onProgress?(index + 1)
            try await uploadHomeworkFile(assignmentId: assignmentId, file: file)
        }
        try await finalizeHomework(assignmentId: assignmentId)
    }

    func finalizeHomework(assignmentId: String) async throws {
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await api.request("/v1/homework/\(assignmentId)/submit", method: "POST", authorized: true)
    }

    func uploadHomeworkFile(assignmentId: String, file: HomeworkPickedFile) async throws {
        struct SessionBody: Encodable {
            let mimeType: String
            let size: Int
            let name: String
        }
        struct SessionResp: Decodable { let upload: HomeworkUploadTarget }
        do {
            let session: SessionResp = try await api.request(
                "/v1/homework/\(assignmentId)/upload-session",
                method: "POST",
                body: SessionBody(mimeType: file.contentType, size: file.byteCount, name: file.name),
                authorized: true
            )
            guard let putURL = URL(string: session.upload.url) else { throw InkAPIError.invalidURL }
            try await api.putFile(to: putURL, fileURL: file.fileURL, headers: session.upload.headers)
            struct Confirm: Encodable {
                let key: String
                let mimeType: String
                let size: Int
                let name: String
            }
            struct OK: Decodable { let ok: Bool }
            let _: OK = try await api.request(
                "/v1/homework/\(assignmentId)/files",
                method: "POST",
                body: Confirm(key: session.upload.key, mimeType: file.contentType, size: file.byteCount, name: file.name),
                authorized: true
            )
        } catch InkAPIError.server(let message) where message.localizedCaseInsensitiveContains("depolama") {
            guard file.byteCount <= 8 * 1024 * 1024 else { throw InkAPIError.server(message) }
            let data = try Data(contentsOf: file.fileURL)
            struct OK: Decodable { let ok: Bool }
            let _: OK = try await api.upload("/v1/homework/\(assignmentId)/files", data: data, contentType: file.contentType)
        }
    }

    func fetchGuide() async throws -> GuideDTO {
        try await api.request("/v1/guide", authorized: true)
    }
}

enum MockCatalog {
    static let videos = [
        VideoDTO(id: "v1", moduleId: "m1", videoNumber: 1.1, title: "Stüdyo güvenliği", description: nil, durationSeconds: 600, thumbnailUrl: nil),
    ]

    static let sample = CatalogResponse(
        modules: [
            ModuleDTO(id: "m1", moduleNumber: 1, title: "Dövmeye Giriş", description: "Temel kavramlar", sortOrder: 1, videoCount: 1),
        ],
        nextVideo: videos.first,
        liveSession: nil
    )

    static let products = ProductsResponse(
        categories: [ProductCategoryDTO(id: "c1", name: "Makineler", imageUrl: nil)],
        products: [ProductDTO(id: "p1", categoryId: "c1", name: "Pro Machine", imageUrl: nil, explanation: "Profesyonel makine", purchaseUrl: "https://inkakademi.com")]
    )

    static let homework: [HomeworkAssignmentDTO] = [
        HomeworkAssignmentDTO(assignmentId: "h1", title: "Linework ödevi", explanation: "PDF yükle", status: "pending", primaryScore: nil, latestScore: nil),
    ]
}
