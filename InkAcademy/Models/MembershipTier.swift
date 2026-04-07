import Foundation

enum MembershipTier: String, Codable, CaseIterable, Identifiable, Comparable {
    case demo
    case cirak
    case kalfa
    case proKalfa

    var id: String { rawValue }

    var rank: Int {
        switch self {
        case .demo: return 0
        case .cirak: return 1
        case .kalfa: return 2
        case .proKalfa: return 3
        }
    }

    var title: String {
        switch self {
        case .demo: return "Demo"
        case .cirak: return "Çırak"
        case .kalfa: return "Kalfa"
        case .proKalfa: return "Pro Kalfa"
        }
    }

    var marketingTitle: String {
        switch self {
        case .demo: return "Başlangıç Erişimi"
        case .cirak: return "Çırak"
        case .kalfa: return "Kalfa"
        case .proKalfa: return "Pro Kalfa"
        }
    }

    var shortDescription: String {
        switch self {
        case .demo:
            return "Açık tanıtım modülleri"
        case .cirak:
            return "Tüm eğitim modülleri"
        case .kalfa:
            return "Mentor destekli ilerleme"
        case .proKalfa:
            return "Canlı yayın ve özel mentor akışı"
        }
    }

    static func < (lhs: MembershipTier, rhs: MembershipTier) -> Bool {
        lhs.rank < rhs.rank
    }
}
