import Foundation

struct ModuleDTO: Identifiable, Decodable, Hashable {
    let id: String
    let moduleNumber: Double
    let title: String
    let description: String?
    let sortOrder: Int
    var videoCount: Int = 0
    var completedCount: Int = 0
    /// Yalnızca crew yanıtlarında.
    var isPublished: Bool? = nil
    var readyCount: Int? = nil

    var numberLabel: String { String(format: "%.0f", moduleNumber) }

    init(id: String, moduleNumber: Double, title: String, description: String?, sortOrder: Int, videoCount: Int = 0, completedCount: Int = 0) {
        self.id = id
        self.moduleNumber = moduleNumber
        self.title = title
        self.description = description
        self.sortOrder = sortOrder
        self.videoCount = videoCount
        self.completedCount = completedCount
    }

    private enum CodingKeys: String, CodingKey {
        case id, moduleNumber, title, description, sortOrder, videoCount, completedCount, isPublished, readyCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        moduleNumber = try c.decode(Double.self, forKey: .moduleNumber)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        videoCount = try c.decodeIfPresent(Int.self, forKey: .videoCount) ?? 0
        completedCount = try c.decodeIfPresent(Int.self, forKey: .completedCount) ?? 0
        isPublished = try c.decodeIfPresent(Bool.self, forKey: .isPublished)
        readyCount = try c.decodeIfPresent(Int.self, forKey: .readyCount)
    }
}

enum VideoStatus: String, Decodable {
    case awaitingUpload = "awaiting_upload"
    case processing
    case ready
    case failed

    var displayName: String {
        switch self {
        case .awaitingUpload: return "Yükleme bekliyor"
        case .processing: return "İşleniyor"
        case .ready: return "Hazır"
        case .failed: return "Hata"
        }
    }
}

struct VideoDTO: Identifiable, Decodable, Hashable {
    let id: String
    let moduleId: String
    let videoNumber: Double
    let title: String
    let description: String?
    let durationSeconds: Int
    let thumbnailUrl: String?
    var status: VideoStatus = .ready
    var isPublished: Bool = true
    var width: Int? = nil
    var height: Int? = nil
    var completed: Bool? = nil
    var lastPositionSeconds: Int? = nil
    var allowTrial: Bool = false

    var numberLabel: String {
        videoNumber.rounded() == videoNumber ? String(format: "%.0f", videoNumber) : String(format: "%.1f", videoNumber)
    }

    var durationLabel: String {
        let h = durationSeconds / 3600, m = (durationSeconds % 3600) / 60, s = durationSeconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    var qualityLabel: String? {
        guard let height, height > 0 else { return nil }
        let short = min(height, width ?? height)
        switch short {
        case 2160...: return "4K"
        case 1440...: return "1440p"
        case 1080...: return "1080p"
        case 720...: return "720p"
        default: return "\(short)p"
        }
    }

    var thumbnailURL: URL? { thumbnailUrl.flatMap(URL.init(string:)) }

    var progressFraction: Double {
        if completed == true { return 1 }
        guard durationSeconds > 0, let last = lastPositionSeconds else { return 0 }
        return min(Double(last) / Double(durationSeconds), 1)
    }
}

struct CatalogResponse: Decodable {
    let modules: [ModuleDTO]
    let nextVideo: VideoDTO?
    let liveSession: LiveSessionDTO?
}

struct ModuleVideosResponse: Decodable {
    let videos: [VideoDTO]
}

struct PlaybackDTO: Decodable {
    let video: VideoDTO
    let hlsUrl: String
    let expiresAt: String
}

// MARK: - Crew eğitim yönetimi

struct CrewModulesResponse: Decodable {
    let modules: [ModuleDTO]
    let videoServiceConfigured: Bool
}

struct ModuleDraft: Equatable {
    var title: String
    var description: String
    var isPublished: Bool
}

struct VideoDraft: Equatable {
    var title: String
    var description: String
    var isPublished: Bool
    var allowTrial: Bool
}

/// Bunny Stream TUS (devam ettirilebilir) yükleme kimlik bilgileri.
struct VideoUploadCredentials: Codable, Hashable {
    let endpoint: String
    let libraryId: String
    let videoId: String
    let expire: Int
    let signature: String
}

struct LiveSessionDTO: Decodable, Identifiable {
    let id: String
    let title: String
    let streamUrl: String
    let thumbnailUrl: String?
    let startsAt: String
}

struct ProductCategoryDTO: Identifiable, Decodable {
    let id: String
    let name: String
    let imageUrl: String?
}

struct ProductImageDTO: Identifiable, Codable, Hashable {
    let id: String
    /// Sunucuda göreli yol (`/media/...`), geliştirme modunda `file://` adresi.
    let url: String

    var resolvedURL: URL? {
        if url.hasPrefix("file://") || url.hasPrefix("https://") || url.hasPrefix("http://") {
            return URL(string: url)
        }
        return URL(string: url, relativeTo: APIConfiguration.baseURL)?.absoluteURL
    }
}

struct ProductDTO: Identifiable, Decodable {
    let id: String
    let categoryId: String
    let name: String
    let imageUrl: String?
    let explanation: String?
    let purchaseUrl: String
    var images: [ProductImageDTO]? = nil
    var isPublished: Bool? = nil

    var gallery: [ProductImageDTO] { images ?? [] }
}

/// Crew'un eklediği ürün linki (ör. Shopier). Yalnızca https kabul edilir.
enum ProductLink {
    /// "shopier.com/abc" gibi şemasız linklere https:// ekler; http ve diğer şemaları reddeder.
    static func normalized(_ raw: String) -> URL? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.contains(" ") else { return nil }
        if !value.contains("://") { value = "https://" + value }
        guard let url = URL(string: value),
              url.scheme?.lowercased() == "https",
              let host = url.host, host.contains("."), !host.hasPrefix("."), !host.hasSuffix(".") else { return nil }
        return url
    }

    static func storeName(for url: URL) -> String {
        let host = (url.host ?? "").lowercased().replacingOccurrences(of: "www.", with: "")
        if host == "shopier.com" || host.hasSuffix(".shopier.com") { return "Shopier" }
        return host
    }
}

struct ProductDraft: Equatable {
    var categoryId: String
    var name: String
    var explanation: String
    var purchaseUrl: String
}

struct ProductsResponse: Decodable {
    let categories: [ProductCategoryDTO]
    let products: [ProductDTO]
}

struct HomeworkAssignmentDTO: Identifiable, Decodable {
    var id: String { assignmentId }
    let assignmentId: String
    var homeworkId: String? = nil
    let title: String
    let explanation: String
    var dueAt: String? = nil
    let status: String
    let primaryScore: Int?
    let latestScore: Int?
    var fileUrl: String? = nil
    var images: [ProductImageDTO]? = nil

    var gallery: [ProductImageDTO] { images ?? [] }
}

/// Crew panelindeki ödev (öğrenci atamasından bağımsız içerik).
struct CrewHomeworkDTO: Identifiable, Decodable {
    let id: String
    let title: String
    let explanation: String
    var dueAt: String? = nil
    var assignedCount: Int? = nil
    var submittedCount: Int? = nil
    var images: [ProductImageDTO]? = nil

    var gallery: [ProductImageDTO] { images ?? [] }
}

struct HomeworkDraft: Equatable {
    var title: String
    var explanation: String
    /// ISO 8601, nil → teslim tarihi yok.
    var dueAt: Date?
}

struct HomeworkListResponse: Decodable {
    let assignments: [HomeworkAssignmentDTO]
}
