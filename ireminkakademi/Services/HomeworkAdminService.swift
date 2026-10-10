import Foundation

/// Crew panelinin ödev yönetimi.
protocol HomeworkAdminServicing {
    func fetchAll() async throws -> [CrewHomeworkDTO]
    func create(_ draft: HomeworkDraft) async throws -> String
    func update(id: String, _ draft: HomeworkDraft) async throws
    func delete(id: String) async throws
    func uploadImage(homeworkId: String, jpegData: Data) async throws -> ProductImageDTO
    func deleteImage(id: String) async throws
}

enum HomeworkAdminServiceFactory {
    static func make() -> HomeworkAdminServicing {
        if APIConfiguration.usesMockBackend || APIConfiguration.usesLocalAuth {
            return LocalHomeworkStore.shared
        }
        return RemoteHomeworkAdminService()
    }
}

private let iso8601: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

final class RemoteHomeworkAdminService: HomeworkAdminServicing {
    private let api = InkAPIClient.shared
    private struct OK: Decodable { let ok: Bool }
    private struct Created: Decodable { let id: String }

    private struct Body: Encodable {
        let title: String
        let explanation: String
        let dueAt: String?
        init(_ draft: HomeworkDraft) {
            title = draft.title
            explanation = draft.explanation
            dueAt = draft.dueAt.map { iso8601.string(from: $0) }
        }

        private enum CodingKeys: String, CodingKey { case title, explanation, dueAt }

        // `dueAt: null` must be sent explicitly so removing the deadline clears it on the server.
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(title, forKey: .title)
            try container.encode(explanation, forKey: .explanation)
            try container.encode(dueAt, forKey: .dueAt)
        }
    }

    func fetchAll() async throws -> [CrewHomeworkDTO] {
        struct Resp: Decodable { let homework: [CrewHomeworkDTO] }
        let resp: Resp = try await api.request("/v1/crew/homework", authorized: true)
        return resp.homework
    }

    func create(_ draft: HomeworkDraft) async throws -> String {
        let created: Created = try await api.request("/v1/crew/homework", method: "POST", body: Body(draft), authorized: true)
        return created.id
    }

    func update(id: String, _ draft: HomeworkDraft) async throws {
        let _: OK = try await api.request("/v1/crew/homework/\(id)", method: "PATCH", body: Body(draft), authorized: true)
    }

    func delete(id: String) async throws {
        let _: OK = try await api.request("/v1/crew/homework/\(id)", method: "DELETE", authorized: true)
    }

    func uploadImage(homeworkId: String, jpegData: Data) async throws -> ProductImageDTO {
        try await api.upload("/v1/crew/homework/\(homeworkId)/images", data: jpegData, contentType: "image/jpeg")
    }

    func deleteImage(id: String) async throws {
        let _: OK = try await api.request("/v1/crew/homework/images/\(id)", method: "DELETE", authorized: true)
    }
}

/// Sunucu bağlı değilken (Debug) crew'un eklediği ödevleri cihazda saklar; öğrenci ekranı da buradan okur.
final class LocalHomeworkStore: HomeworkAdminServicing {
    static let shared = LocalHomeworkStore()

    private struct StoredHomework: Codable {
        var id: String
        var title: String
        var explanation: String
        var dueAt: Date?
        var imageFiles: [String]
        var createdAt: Date
    }

    private let storeURL: URL
    private let imagesDirectory: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LocalHomework", isDirectory: true)
        storeURL = base.appendingPathComponent("homework.json")
        imagesDirectory = base.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    func fetchAll() async throws -> [CrewHomeworkDTO] {
        load().sorted { $0.createdAt > $1.createdAt }.map { item in
            CrewHomeworkDTO(
                id: item.id,
                title: item.title,
                explanation: item.explanation,
                dueAt: item.dueAt.map { iso8601.string(from: $0) },
                assignedCount: nil,
                submittedCount: nil,
                images: images(for: item)
            )
        }
    }

    /// Öğrenci görünümü: her ödev bekleyen bir atama olarak döner.
    func studentAssignments() -> [HomeworkAssignmentDTO] {
        load().sorted { $0.createdAt > $1.createdAt }.map { item in
            HomeworkAssignmentDTO(
                assignmentId: "local-\(item.id)",
                homeworkId: item.id,
                title: item.title,
                explanation: item.explanation,
                dueAt: item.dueAt.map { iso8601.string(from: $0) },
                status: "pending",
                primaryScore: nil,
                latestScore: nil,
                images: images(for: item)
            )
        }
    }

    func create(_ draft: HomeworkDraft) async throws -> String {
        var items = load()
        let id = UUID().uuidString
        items.append(StoredHomework(id: id, title: draft.title, explanation: draft.explanation, dueAt: draft.dueAt, imageFiles: [], createdAt: .now))
        save(items)
        return id
    }

    func update(id: String, _ draft: HomeworkDraft) async throws {
        var items = load()
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].title = draft.title
        items[index].explanation = draft.explanation
        items[index].dueAt = draft.dueAt
        save(items)
    }

    func delete(id: String) async throws {
        var items = load()
        if let item = items.first(where: { $0.id == id }) {
            item.imageFiles.forEach { try? FileManager.default.removeItem(at: imagesDirectory.appendingPathComponent($0)) }
        }
        items.removeAll { $0.id == id }
        save(items)
    }

    func uploadImage(homeworkId: String, jpegData: Data) async throws -> ProductImageDTO {
        var items = load()
        guard let index = items.firstIndex(where: { $0.id == homeworkId }) else { throw InkAPIError.server("Not found") }
        let file = "\(UUID().uuidString).jpg"
        let url = imagesDirectory.appendingPathComponent(file)
        try jpegData.write(to: url, options: [.atomic, .completeFileProtection])
        items[index].imageFiles.append(file)
        save(items)
        return ProductImageDTO(id: file, url: url.absoluteString)
    }

    func deleteImage(id: String) async throws {
        var items = load()
        for index in items.indices { items[index].imageFiles.removeAll { $0 == id } }
        try? FileManager.default.removeItem(at: imagesDirectory.appendingPathComponent(id))
        save(items)
    }

    private func images(for item: StoredHomework) -> [ProductImageDTO] {
        item.imageFiles.map { ProductImageDTO(id: $0, url: imagesDirectory.appendingPathComponent($0).absoluteString) }
    }

    private func load() -> [StoredHomework] {
        guard let data = try? Data(contentsOf: storeURL),
              let items = try? JSONDecoder().decode([StoredHomework].self, from: data) else { return [] }
        return items
    }

    private func save(_ items: [StoredHomework]) {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: storeURL, options: [.atomic, .completeFileProtection])
        }
    }
}
