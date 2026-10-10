import Foundation

enum BadgeID: String, CaseIterable, Codable {
    case ilkDers = "badge_ilk_ders"
    case hijyenTemeli = "badge_hijyen_temeli"
    case lineworkBaslangici = "badge_linework_baslangici"
    case stencilCalismasi = "badge_stencil_calismasi"
    case golgelemeCiragi = "badge_golgeleme_ciragi"
    case kalfaAdayi = "badge_kalfa_adayi"
    case ustaYolu = "badge_usta_yolu"
}

struct Badge: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let imageAssetName: String
    let earnedImageAssetName: String?
    let xpReward: Int
    let requirementDescription: String
    var isEarned: Bool

    var displayImageName: String {
        if isEarned, let earnedImageAssetName {
            return earnedImageAssetName
        }
        return imageAssetName
    }

    static let catalog: [Badge] = [
        Badge(
            id: BadgeID.ilkDers.rawValue,
            title: "İlk Ders",
            description: "İlk dersini tamamladın.",
            icon: "play.circle.fill",
            imageAssetName: "BadgeIlkDers",
            earnedImageAssetName: "BadgeIlkDers",
            xpReward: 40,
            requirementDescription: "İlk ders tamamlandı",
            isEarned: false
        ),
        Badge(
            id: BadgeID.hijyenTemeli.rawValue,
            title: "Hijyen Temeli",
            description: "Hijyen modülünü bitirdin.",
            icon: "cross.case.fill",
            imageAssetName: "BadgeHijyenTemeli",
            earnedImageAssetName: nil,
            xpReward: 120,
            requirementDescription: "Hijyen modülü tamamlandı",
            isEarned: false
        ),
        Badge(
            id: BadgeID.lineworkBaslangici.rawValue,
            title: "Linework Başlangıcı",
            description: "Linework dersini tamamladın.",
            icon: "pencil.and.outline",
            imageAssetName: "BadgeLinework",
            earnedImageAssetName: nil,
            xpReward: 100,
            requirementDescription: "Linework modülü / dersi tamamlandı",
            isEarned: false
        ),
        Badge(
            id: BadgeID.stencilCalismasi.rawValue,
            title: "Stencil Çalışması",
            description: "Stencil pratiğini tamamladın.",
            icon: "square.on.square",
            imageAssetName: "BadgeStencil",
            earnedImageAssetName: nil,
            xpReward: 120,
            requirementDescription: "Stencil modülü tamamlandı",
            isEarned: false
        ),
        Badge(
            id: BadgeID.golgelemeCiragi.rawValue,
            title: "Gölgeleme Çırağı",
            description: "Gölgeleme dersini tamamladın.",
            icon: "circle.hexagongrid.fill",
            imageAssetName: "BadgeGolgeleme",
            earnedImageAssetName: nil,
            xpReward: 90,
            requirementDescription: "Shading dersi tamamlandı",
            isEarned: false
        ),
        Badge(
            id: BadgeID.kalfaAdayi.rawValue,
            title: "Kalfa Adayı",
            description: "Tüm temel modülleri tamamladın.",
            icon: "star.circle.fill",
            imageAssetName: "BadgeKalfaAdayi",
            earnedImageAssetName: nil,
            xpReward: 200,
            requirementDescription: "Tüm temel modüller tamamlandı",
            isEarned: false
        ),
        Badge(
            id: BadgeID.ustaYolu.rawValue,
            title: "Usta Yolu",
            description: "İleri seviye modülü tamamladın.",
            icon: "crown.fill",
            imageAssetName: "BadgeUstaYolu",
            earnedImageAssetName: nil,
            xpReward: 350,
            requirementDescription: "İleri seviye modül tamamlandı",
            isEarned: false
        )
    ]
}
