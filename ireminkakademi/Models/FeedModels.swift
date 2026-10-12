import Foundation

struct FeedAuthorDTO: Identifiable, Decodable, Hashable {
    let userId: String
    var username: String? = nil
    var displayName: String? = nil
    var firstName: String? = nil
    var role: String? = nil
    var photoUrl: String? = nil
    var frame: AvatarFrame? = nil
    var level: Int? = nil
    var rank: String? = nil
    var rankLabel: String? = nil

    var id: String { userId }
    var photoURL: URL? { MediaURL.resolve(photoUrl) }
    var isStaff: Bool { role == "crew" || role == "super_admin" }
    var academyRank: AcademyRank? {
        guard !isStaff else { return nil }
        if let rank, let parsed = AcademyRank(rawValue: rank) { return parsed }
        if let level { return .forLevel(level) }
        return nil
    }
    var publicRankCaption: String? {
        guard let level, !isStaff else { return nil }
        let label = rankLabel ?? academyRank?.label ?? "Çırak"
        return "\(label)  ·  Seviye \(level)"
    }
    var name: String {
        if let displayName, !displayName.isEmpty { return displayName }
        if let username, !username.isEmpty { return "@\(username)" }
        return firstName ?? "Üye"
    }
    var initials: String {
        let source = firstName ?? displayName ?? username ?? "?"
        return String(source.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased(with: Locale(identifier: "tr_TR"))
    }
    var avatarFrame: AvatarFrame { frame ?? .gray }
}

struct FeedMediaDTO: Identifiable, Decodable, Hashable {
    let id: String
    let kind: String
    var mimeType: String? = nil
    var url: String? = nil

    var resolvedURL: URL? { MediaURL.resolve(url) }
    var isVideo: Bool { kind == "video" }
}

struct FeedPostDTO: Identifiable, Decodable, Hashable {
    let id: String
    var body: String = ""
    let createdAt: String
    var updatedAt: String? = nil
    let author: FeedAuthorDTO
    var media: [FeedMediaDTO] = []
    var likeCount: Int = 0
    var replyCount: Int = 0
    var liked: Bool = false
    var canDelete: Bool = false

    var previewText: String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return media.contains(where: \.isVideo) ? "Video paylaştı" : (media.isEmpty ? "" : "Görsel paylaştı") }
        return trimmed
    }
}

struct FeedReplyDTO: Identifiable, Decodable, Hashable {
    let id: String
    let postId: String
    var parentReplyId: String? = nil
    let body: String
    let createdAt: String
    let author: FeedAuthorDTO
    var media: [FeedMediaDTO] = []
    var canDelete: Bool = false
}

struct FeedListResponse: Decodable {
    var posts: [FeedPostDTO] = []
    var nextCursor: String? = nil
}

struct FeedLatestResponse: Decodable {
    var post: FeedPostDTO? = nil
}

struct FeedPostResponse: Decodable {
    let post: FeedPostDTO
    var xpAwarded: Int? = nil
    var totalXp: Int? = nil
}

struct FeedLikeResponse: Decodable {
    let liked: Bool
    let likeCount: Int
    var xpAwarded: Int? = nil
    var totalXp: Int? = nil
}

struct FeedRepliesResponse: Decodable {
    var replies: [FeedReplyDTO] = []
}

struct FeedReplyResponse: Decodable {
    var reply: FeedReplyDTO
    var xpAwarded: Int? = nil
    var totalXp: Int? = nil
}

enum RelativeTimeFormat {
    static func display(_ value: String?) -> String {
        guard let date = HomeworkDateFormat.parse(value) else { return "" }
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 45 { return "şimdi" }
        if seconds < 3600 { return "\(max(1, seconds / 60)) dk" }
        if seconds < 86_400 { return "\(seconds / 3600) sa" }
        if seconds < 86_400 * 7 { return "\(seconds / 86_400) gün" }
        return HomeworkDateFormat.display(value) ?? ""
    }
}
