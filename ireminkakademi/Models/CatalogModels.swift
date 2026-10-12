import Foundation

struct EducationProgramDTO: Identifiable, Decodable, Hashable {
    let id: String
    var slug: String? = nil
    let title: String
    var description: String? = nil
    var instructorName: String? = nil
    var coverImageUrl: String? = nil
    var sortOrder: Int = 0
    var isPublished: Bool? = nil
    var moduleCount: Int = 0
    var videoCount: Int = 0
    var completedCount: Int = 0
    var displayIndex: Int? = nil

    var numberLabel: String {
        if let displayIndex, displayIndex > 0 { return "\(displayIndex)" }
        return sortOrder > 0 ? "\(sortOrder)" : "1"
    }

    var subtitle: String {
        let modules = moduleCount == 1 ? "1 modül" : "\(moduleCount) modül"
        guard videoCount > 0 else { return modules }
        return "\(modules) · \(videoCount) ders"
    }

    private enum CodingKeys: String, CodingKey {
        case id, slug, title, description, instructorName, coverImageUrl, sortOrder, isPublished, moduleCount, videoCount, completedCount, displayIndex
    }

    init(
        id: String,
        slug: String? = nil,
        title: String,
        description: String? = nil,
        instructorName: String? = nil,
        coverImageUrl: String? = nil,
        sortOrder: Int = 0,
        isPublished: Bool? = nil,
        moduleCount: Int = 0,
        videoCount: Int = 0,
        completedCount: Int = 0,
        displayIndex: Int? = nil
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.description = description
        self.instructorName = instructorName
        self.coverImageUrl = coverImageUrl
        self.sortOrder = sortOrder
        self.isPublished = isPublished
        self.moduleCount = moduleCount
        self.videoCount = videoCount
        self.completedCount = completedCount
        self.displayIndex = displayIndex
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        slug = try c.decodeIfPresent(String.self, forKey: .slug)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        instructorName = try c.decodeIfPresent(String.self, forKey: .instructorName)
        coverImageUrl = try c.decodeIfPresent(String.self, forKey: .coverImageUrl)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        isPublished = try c.decodeIfPresent(Bool.self, forKey: .isPublished)
        moduleCount = try c.decodeIfPresent(Int.self, forKey: .moduleCount) ?? 0
        videoCount = try c.decodeIfPresent(Int.self, forKey: .videoCount) ?? 0
        completedCount = try c.decodeIfPresent(Int.self, forKey: .completedCount) ?? 0
        displayIndex = try c.decodeIfPresent(Int.self, forKey: .displayIndex)
    }
}

struct ModuleDTO: Identifiable, Decodable, Hashable {
    let id: String
    var educationProgramId: String? = nil
    let moduleNumber: Double
    let title: String
    let description: String?
    let sortOrder: Int
    var videoCount: Int = 0
    var completedCount: Int = 0
    /// Yalnızca crew yanıtlarında.
    var isPublished: Bool? = nil
    var readyCount: Int? = nil
    var displayLabel: String? = nil

    var numberLabel: String {
        if let displayLabel, !displayLabel.isEmpty { return displayLabel }
        return String(format: "%.0f", moduleNumber)
    }

    init(
        id: String,
        moduleNumber: Double,
        title: String,
        description: String?,
        sortOrder: Int,
        videoCount: Int = 0,
        completedCount: Int = 0,
        educationProgramId: String? = nil,
        displayLabel: String? = nil
    ) {
        self.id = id
        self.educationProgramId = educationProgramId
        self.moduleNumber = moduleNumber
        self.title = title
        self.description = description
        self.sortOrder = sortOrder
        self.videoCount = videoCount
        self.completedCount = completedCount
        self.displayLabel = displayLabel
    }

    private enum CodingKeys: String, CodingKey {
        case id, educationProgramId, moduleNumber, title, description, sortOrder, videoCount, completedCount, isPublished, readyCount, displayLabel
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        educationProgramId = try c.decodeIfPresent(String.self, forKey: .educationProgramId)
        moduleNumber = try c.decode(Double.self, forKey: .moduleNumber)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        videoCount = try c.decodeIfPresent(Int.self, forKey: .videoCount) ?? 0
        completedCount = try c.decodeIfPresent(Int.self, forKey: .completedCount) ?? 0
        isPublished = try c.decodeIfPresent(Bool.self, forKey: .isPublished)
        readyCount = try c.decodeIfPresent(Int.self, forKey: .readyCount)
        displayLabel = try c.decodeIfPresent(String.self, forKey: .displayLabel)
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
    var locked: Bool? = nil

    func isLocked(for user: User?) -> Bool {
        guard let user, user.role == .student else { return false }
        if user.membershipStatus.isPaid { return false }
        if user.membershipStatus == .trial { return !allowTrial }
        return true
    }

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

struct ProgramsResponse: Decodable {
    let programs: [EducationProgramDTO]
}

struct ProgramDetailResponse: Decodable {
    let program: EducationProgramDTO
    let modules: [ModuleDTO]
}

struct ModuleVideosResponse: Decodable {
    let videos: [VideoDTO]
}

struct PlaybackDTO: Decodable {
    let video: VideoDTO
    let hlsUrl: String
    let embedUrl: String?
    let expiresAt: String
}

// MARK: - Crew eğitim yönetimi

struct CrewModulesResponse: Decodable {
    let modules: [ModuleDTO]
    var programs: [EducationProgramDTO] = []
    let videoServiceConfigured: Bool

    private enum CodingKeys: String, CodingKey {
        case modules, programs, videoServiceConfigured
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        modules = try c.decode([ModuleDTO].self, forKey: .modules)
        programs = try c.decodeIfPresent([EducationProgramDTO].self, forKey: .programs) ?? []
        videoServiceConfigured = try c.decodeIfPresent(Bool.self, forKey: .videoServiceConfigured) ?? true
    }
}

struct ProgramDraft: Equatable {
    var title: String
    var description: String
    var instructorName: String
    var isPublished: Bool
}

struct ModuleDraft: Equatable {
    var title: String
    var description: String
    var isPublished: Bool
    var educationProgramId: String? = nil
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

struct ProductCategoryDTO: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let imageUrl: String?
    var products: [ProductDTO]? = nil

    init(id: String, name: String, imageUrl: String?, products: [ProductDTO]? = nil) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.products = products
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, imageUrl, products
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        products = try c.decodeIfPresent([ProductDTO].self, forKey: .products)
    }
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

struct ProductDTO: Identifiable, Decodable, Hashable {
    let id: String
    let categoryId: String
    let name: String
    let imageUrl: String?
    let explanation: String?
    let purchaseUrl: String
    var images: [ProductImageDTO]? = nil
    var isPublished: Bool? = nil

    var gallery: [ProductImageDTO] { images ?? [] }

    init(
        id: String,
        categoryId: String,
        name: String,
        imageUrl: String?,
        explanation: String?,
        purchaseUrl: String,
        images: [ProductImageDTO]? = nil,
        isPublished: Bool? = nil
    ) {
        self.id = id
        self.categoryId = categoryId
        self.name = name
        self.imageUrl = imageUrl
        self.explanation = explanation
        self.purchaseUrl = purchaseUrl
        self.images = images
        self.isPublished = isPublished
    }

    private enum CodingKeys: String, CodingKey {
        case id, categoryId, name, imageUrl, explanation, purchaseUrl, images, isPublished
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        categoryId = (try c.decodeIfPresent(String.self, forKey: .categoryId) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        explanation = try c.decodeIfPresent(String.self, forKey: .explanation)
        purchaseUrl = try c.decodeIfPresent(String.self, forKey: .purchaseUrl) ?? ""
        images = try c.decodeIfPresent([ProductImageDTO].self, forKey: .images)
        if let flag = try? c.decodeIfPresent(Bool.self, forKey: .isPublished) {
            isPublished = flag
        } else if let number = try? c.decodeIfPresent(Int.self, forKey: .isPublished) {
            isPublished = number != 0
        } else {
            isPublished = nil
        }
    }
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
    var files: [HomeworkFileDTO]? = nil
    var images: [ProductImageDTO]? = nil
    var allowTrial: Bool? = nil
    var allowPaid: Bool? = nil
    var locked: Bool? = nil
    var overdue: Bool? = nil

    var gallery: [ProductImageDTO] { images ?? [] }
    var submittedFiles: [HomeworkFileDTO] { files ?? [] }

    var isPastDue: Bool {
        if overdue == true { return true }
        guard let date = HomeworkDateFormat.parse(dueAt) else { return false }
        return date < .now
    }

    func isLocked(for user: User?) -> Bool {
        guard let user, user.role == .student else { return false }
        if user.membershipStatus.isPaid { return allowPaid == false }
        if user.membershipStatus == .trial { return allowTrial != true }
        return true
    }
}

struct HomeworkFileDTO: Identifiable, Decodable, Hashable {
    let id: String
    var url: String? = nil
    var mime: String? = nil
    var size: Int? = nil
    var name: String? = nil

    var resolvedURL: URL? { MediaURL.resolve(url) }
}

struct HomeworkUploadTarget: Decodable {
    let url: String
    let method: String
    let headers: [String: String]
    let key: String
    var maxBytes: Int? = nil
    var remainingBytes: Int? = nil
    var mimeType: String? = nil
    var fileName: String? = nil
}

/// Crew panelindeki ödev (öğrenci atamasından bağımsız içerik).
struct CrewHomeworkDTO: Identifiable, Decodable {
    let id: String
    let title: String
    let explanation: String
    var dueAt: String? = nil
    var assignedCount: Int? = nil
    var submittedCount: Int? = nil
    var allowTrial: Bool? = nil
    var allowPaid: Bool? = nil
    var images: [ProductImageDTO]? = nil

    var gallery: [ProductImageDTO] { images ?? [] }
}

struct HomeworkDraft: Equatable {
    var title: String
    var explanation: String
    /// ISO 8601, nil → teslim tarihi yok.
    var dueAt: Date?
    var allowTrial: Bool = false
    var allowPaid: Bool = true
}

struct HomeworkListResponse: Decodable {
    let assignments: [HomeworkAssignmentDTO]
}
