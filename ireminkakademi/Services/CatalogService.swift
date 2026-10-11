import Foundation

@Observable
final class CatalogService {
    @ObservationIgnored private let api = InkAPIClient.shared

    func fetchCatalog() async throws -> CatalogResponse {
        if APIConfiguration.usesMockBackend { return MockCatalog.sample }
        return try await api.request("/v1/modules", authorized: true)
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
        return try await api.request("/v1/badges", authorized: true)
    }

    func completeWeeklyGame() async throws -> BadgeProgressResponse {
        try await api.request("/v1/game/weekly-complete", method: "POST", authorized: true)
    }

    func submitHomework(assignmentId: String, data: Data, contentType: String) async throws {
        guard !APIConfiguration.usesMockBackend else { return }
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await api.upload("/v1/homework/\(assignmentId)/submit", data: data, contentType: contentType)
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
