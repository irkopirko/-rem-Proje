import Foundation

enum UserRole: String, Codable, Sendable {
    case student
    case crew
    case superAdmin = "super_admin"
}

enum MembershipStatus: String, Codable, Sendable {
    case trial
    case trialExpired = "trial_expired"
    case plus
    case light
    case lifePlus = "life_plus"
    case none
}

extension MembershipStatus {
    var isPaid: Bool {
        switch self {
        case .plus, .light, .lifePlus: return true
        default: return false
        }
    }

    var displayName: String {
        switch self {
        case .trial: return "Deneme Üyeliği"
        case .trialExpired: return "Deneme süresi doldu"
        case .plus: return "Plus"
        case .light: return "Light"
        case .lifePlus: return "Life Plus"
        case .none: return "Üyelik yok"
        }
    }
}

struct User: Codable, Sendable, Identifiable {
    let id: String
    let userNo: Int?
    var username: String? = nil
    var birthDate: String? = nil
    let email: String
    let firstName: String
    let lastName: String
    let role: UserRole
    let membershipStatus: MembershipStatus
    let profilePhotoUrl: String?
    var xp: Int? = nil
    var totalXp: Int? = nil
    var level: Int? = nil
    var xpIntoLevel: Int? = nil
    var xpForNextLevel: Int? = nil

    var displayName: String { "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) }

    var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        return (first + last).uppercased(with: Locale(identifier: "tr_TR"))
    }

    var profilePhotoURL: URL? { MediaURL.resolve(profilePhotoUrl) }

    var canSeeHomework: Bool { role == .crew || role == .superAdmin || membershipStatus.isPaid }

    var avatarFrame: AvatarFrame { .of(role: role, membership: membershipStatus, username: username) }

    var isVerified: Bool { avatarFrame == .purple }

    /// Crew / super admin öğrenci merdiveni (Çırak–Usta) kullanmaz.
    var showsStudentRank: Bool { role == .student }

    var levelProgress: LevelProgress { LevelMath.from(xp: totalXp ?? xp ?? 0) }

    /// "yyyy-MM-dd" → "12 Mart 1998"
    var formattedBirthDate: String? {
        guard let birthDate else { return nil }
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: String(birthDate.prefix(10))) else { return birthDate }
        let output = DateFormatter()
        output.locale = Locale(identifier: "tr_TR")
        output.dateFormat = "d MMMM yyyy"
        return output.string(from: date)
    }
}

/// Sunucu `/media/...` göreli yolları veya tam CDN adresleri döndürür.
enum MediaURL {
    static func resolve(_ value: String?) -> URL? {
        guard let value, !value.isEmpty else { return nil }
        if value.hasPrefix("https://") || value.hasPrefix("http://") || value.hasPrefix("file://") {
            return URL(string: value)
        }
        return URL(string: value, relativeTo: APIConfiguration.baseURL)?.absoluteURL
    }
}

enum AvatarFrame: String, Codable, Sendable {
    case gray
    case gold
    case purple

    private static let purpleUsernames: Set<String> = ["inkakademicrew", "vuralemekci", "iremcelik"]

    static func of(role: UserRole, membership: MembershipStatus, username: String? = nil) -> AvatarFrame {
        if role == .crew { return .purple }
        if let username, purpleUsernames.contains(UsernameRules.normalize(username)) { return .purple }
        return membership.isPaid ? .gold : .gray
    }
}

enum UsernameRules {
    static let caption = "3–20 karakter; küçük harf, rakam, nokta ve alt çizgi kullanabilirsin."

    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func isValid(_ raw: String) -> Bool {
        let value = normalize(raw)
        guard value.range(of: #"^[a-z0-9._]{3,20}$"#, options: .regularExpression) != nil else { return false }
        return !(value.hasPrefix(".") || value.hasPrefix("_") || value.hasSuffix(".") || value.hasSuffix("_") || value.contains(".."))
    }

    static let reserved: Set<String> = [
        "admin", "administrator", "root", "support", "destek", "crew", "inkakademi",
        "ink.akademi", "inkakademicrew", "moderator", "system", "superadmin",
    ]
}
