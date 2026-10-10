import Foundation

/// Uygulama genelindeki ders kataloğu modülü (`Lesson` tabanlı, Supabase / mock JSON).
struct CourseModule: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var description: String
    var imageURL: URL?
    var lessons: [Lesson]
    var isLocked: Bool

    /// Seviye etiketi (Supabase sonrası eşlenecek); şimdilik metin.
    var levelRequirementTitle: String
    var xpReward: Int
    var isRequired: Bool
    var isAdvanced: Bool
    var relatedProductIds: [String]
    var practiceTaskIds: [String]

    var completedLessonsCount: Int {
        lessons.filter(\.isCompleted).count
    }

    var progressPercent: Double {
        guard !lessons.isEmpty else { return 0 }
        return Double(completedLessonsCount) / Double(lessons.count)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, imageURL, lessons, isLocked
        case levelRequirementTitle, xpReward, isRequired, isAdvanced, relatedProductIds, practiceTaskIds
    }

    init(
        id: String,
        title: String,
        description: String,
        imageURL: URL?,
        lessons: [Lesson],
        isLocked: Bool,
        levelRequirementTitle: String = "Acemi",
        xpReward: Int = 0,
        isRequired: Bool = true,
        isAdvanced: Bool = false,
        relatedProductIds: [String] = [],
        practiceTaskIds: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.lessons = lessons
        self.isLocked = isLocked
        self.levelRequirementTitle = levelRequirementTitle
        self.xpReward = xpReward
        self.isRequired = isRequired
        self.isAdvanced = isAdvanced
        self.relatedProductIds = relatedProductIds
        self.practiceTaskIds = practiceTaskIds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decode(String.self, forKey: .description)
        imageURL = try c.decodeIfPresent(URL.self, forKey: .imageURL)
        lessons = try c.decodeIfPresent([Lesson].self, forKey: .lessons) ?? []
        isLocked = try c.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        levelRequirementTitle = try c.decodeIfPresent(String.self, forKey: .levelRequirementTitle) ?? "Acemi"
        xpReward = try c.decodeIfPresent(Int.self, forKey: .xpReward) ?? 0
        isRequired = try c.decodeIfPresent(Bool.self, forKey: .isRequired) ?? true
        isAdvanced = try c.decodeIfPresent(Bool.self, forKey: .isAdvanced) ?? false
        relatedProductIds = try c.decodeIfPresent([String].self, forKey: .relatedProductIds) ?? []
        practiceTaskIds = try c.decodeIfPresent([String].self, forKey: .practiceTaskIds) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(description, forKey: .description)
        try c.encodeIfPresent(imageURL, forKey: .imageURL)
        try c.encode(lessons, forKey: .lessons)
        try c.encode(isLocked, forKey: .isLocked)
        try c.encode(levelRequirementTitle, forKey: .levelRequirementTitle)
        try c.encode(xpReward, forKey: .xpReward)
        try c.encode(isRequired, forKey: .isRequired)
        try c.encode(isAdvanced, forKey: .isAdvanced)
        try c.encode(relatedProductIds, forKey: .relatedProductIds)
        try c.encode(practiceTaskIds, forKey: .practiceTaskIds)
    }
}
