import Foundation

enum AcademyRank: String, Codable, Sendable {
    case cirak
    case kalfa
    case usta

    var label: String {
        switch self {
        case .cirak: return "Çırak"
        case .kalfa: return "Kalfa"
        case .usta: return "Usta"
        }
    }

    var starCount: Int {
        switch self {
        case .cirak: return 1
        case .kalfa: return 2
        case .usta: return 3
        }
    }

    static func forLevel(_ level: Int) -> AcademyRank {
        if level >= 20 { return .usta }
        if level >= 10 { return .kalfa }
        return .cirak
    }
}

struct LevelProgress: Equatable, Sendable {
    let totalXp: Int
    let level: Int
    let xpIntoLevel: Int
    let xpForNextLevel: Int

    var rank: AcademyRank { .forLevel(level) }

    var xpToNextLevel: Int { max(xpForNextLevel - xpIntoLevel, 0) }

    var fraction: Double {
        guard xpForNextLevel > 0 else { return 1 }
        return min(Double(xpIntoLevel) / Double(xpForNextLevel), 1)
    }

    var caption: String {
        "\(rank.label)  ·  Seviye \(level)  ·  \(totalXp) XP"
    }

    var nextCaption: String {
        guard xpForNextLevel > 0 else { return "En üst seviye" }
        return "Sonraki seviye: \(xpIntoLevel)/\(xpForNextLevel) XP"
    }
}

enum LevelMath {
    /// 0→1 = 100, then each step is the previous requirement × 1.25, rounded to nearest integer.
    static func xpRequired(forLevel level: Int) -> Int {
        guard level > 0 else { return 0 }
        var need = 100
        if level == 1 { return need }
        for _ in 1..<level {
            need = Int((Double(need) * 1.25).rounded(.toNearestOrAwayFromZero))
        }
        return need
    }

    static func from(xp raw: Int) -> LevelProgress {
        var remaining = max(0, raw)
        let total = remaining
        var level = 0
        while level < 500 {
            let need = xpRequired(forLevel: level + 1)
            if remaining < need {
                return LevelProgress(totalXp: total, level: level, xpIntoLevel: remaining, xpForNextLevel: need)
            }
            remaining -= need
            level += 1
        }
        return LevelProgress(totalXp: total, level: level, xpIntoLevel: remaining, xpForNextLevel: 0)
    }
}

struct BadgeDTO: Identifiable, Decodable, Hashable {
    let slug: String
    let title: String
    let description: String?
    let xpReward: Int
    var imageUrl: String?
    var earnedAt: String?

    var id: String { slug }
    var isEarned: Bool { earnedAt != nil }
    var imageURL: URL? { MediaURL.resolve(imageUrl) }

    var localImageName: String? {
        guard let hex = hexAssetIndex else { return legacyImageName }
        let base = String(format: "BadgeHex%02d", hex)
        return isEarned ? base : base + "Gray"
    }

    private var hexAssetIndex: Int? {
        switch slug {
        case "face-shown": return 1
        case "first-needle": return 2
        case "hello-studio": return 3
        case "first-lesson": return 4
        case "module-closed": return 5
        case "weekly-hunter": return 6
        case "homework-book": return 7
        case "pen-opened", "stencil": return 8
        case "linework": return 9
        case "streak-3": return 10
        case "three-modules": return 11
        case "chat-voice": return 12
        case "revise-master": return 13
        case "streak-7": return 14
        case "journeyman": return 15
        case "apprentice", "golgeleme": return 16
        case "master-candidate": return 17
        case "game-collection": return 18
        case "ink-master": return 19
        case "academy-graduate": return 20
        default: return nil
        }
    }

    private var legacyImageName: String? {
        switch slug {
        case "first-needle": return "BadgeHijyenTemeli"
        case "first-lesson": return "BadgeIlkDers"
        case "linework": return "BadgeLinework"
        case "journeyman": return "BadgeKalfaAdayi"
        case "master-candidate": return "BadgeUstaYolu"
        case "stencil", "pen-opened": return "BadgeStencil"
        case "golgeleme", "apprentice": return "BadgeGolgeleme"
        default: return nil
        }
    }

    var symbolName: String {
        switch slug {
        case "first-needle": return "paintbrush.pointed.fill"
        case "face-shown": return "person.crop.circle.badge.checkmark"
        case "hello-studio": return "bubble.left.fill"
        case "first-lesson": return "play.circle.fill"
        case "apprentice": return "hands.sparkles"
        case "weekly-hunter": return "eye.fill"
        case "pen-opened": return "pencil"
        case "linework": return "scribble.variable"
        case "journeyman": return "hammer.fill"
        case "streak-3": return "flame"
        case "module-closed": return "rectangle.stack.fill"
        case "chat-voice": return "megaphone.fill"
        case "revise-master": return "arrow.uturn.backward.circle.fill"
        case "streak-7": return "flame.fill"
        case "homework-book": return "book.closed.fill"
        case "master-candidate": return "star.fill"
        case "three-modules": return "square.stack.3d.up.fill"
        case "game-collection": return "gamecontroller.fill"
        case "ink-master": return "drop.fill"
        case "academy-graduate": return "graduationcap.fill"
        default: return "rosette"
        }
    }
}

struct BadgeProgressResponse: Decodable {
    let totalXp: Int
    let level: Int
    let xpIntoLevel: Int
    let xpForNextLevel: Int
    let badges: [BadgeDTO]
    var gamePlayedToday: Bool?
    var newlyEarned: [BadgeDTO]?
}
