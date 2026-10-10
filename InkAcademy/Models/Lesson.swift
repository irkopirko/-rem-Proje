import Foundation

struct Lesson: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var videoURL: URL?
    var duration: TimeInterval
    var order: Int
    var isCompleted: Bool
    var description: String

    var xpReward: Int
    var relatedProductIds: [String]
    var qrCodeValue: String?
    var hasQuiz: Bool
    var hasAssignment: Bool

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, videoURL, duration, order, isCompleted, description
        case xpReward, relatedProductIds, qrCodeValue, hasQuiz, hasAssignment
    }

    init(
        id: String,
        title: String,
        videoURL: URL?,
        duration: TimeInterval,
        order: Int,
        isCompleted: Bool,
        description: String,
        xpReward: Int = 40,
        relatedProductIds: [String] = [],
        qrCodeValue: String? = nil,
        hasQuiz: Bool = false,
        hasAssignment: Bool = false
    ) {
        self.id = id
        self.title = title
        self.videoURL = videoURL
        self.duration = duration
        self.order = order
        self.isCompleted = isCompleted
        self.description = description
        self.xpReward = xpReward
        self.relatedProductIds = relatedProductIds
        self.qrCodeValue = qrCodeValue
        self.hasQuiz = hasQuiz
        self.hasAssignment = hasAssignment
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        videoURL = try c.decodeIfPresent(URL.self, forKey: .videoURL)
        duration = try c.decode(TimeInterval.self, forKey: .duration)
        order = try c.decode(Int.self, forKey: .order)
        isCompleted = try c.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        description = try c.decode(String.self, forKey: .description)
        xpReward = try c.decodeIfPresent(Int.self, forKey: .xpReward) ?? 40
        relatedProductIds = try c.decodeIfPresent([String].self, forKey: .relatedProductIds) ?? []
        qrCodeValue = try c.decodeIfPresent(String.self, forKey: .qrCodeValue)
        hasQuiz = try c.decodeIfPresent(Bool.self, forKey: .hasQuiz) ?? false
        hasAssignment = try c.decodeIfPresent(Bool.self, forKey: .hasAssignment) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(videoURL, forKey: .videoURL)
        try c.encode(duration, forKey: .duration)
        try c.encode(order, forKey: .order)
        try c.encode(isCompleted, forKey: .isCompleted)
        try c.encode(description, forKey: .description)
        try c.encode(xpReward, forKey: .xpReward)
        try c.encode(relatedProductIds, forKey: .relatedProductIds)
        try c.encodeIfPresent(qrCodeValue, forKey: .qrCodeValue)
        try c.encode(hasQuiz, forKey: .hasQuiz)
        try c.encode(hasAssignment, forKey: .hasAssignment)
    }
}
