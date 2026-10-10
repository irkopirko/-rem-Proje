import Foundation

struct PaywallOffer: Identifiable, Hashable {
    let id: String
    let tier: MembershipTier
    let eyebrow: String
    let title: String
    let subtitle: String
    let price: String
    let originalPrice: String?
    let badge: String?
    let ctaTitle: String
    let primaryFeatures: [String]
    let secondaryFeatures: [String]
    let lockedFeatures: [String]
    let footnote: String
    let comparisonCaption: String

    static func forTier(_ tier: MembershipTier, moduleTitle: String? = nil) -> PaywallOffer {
        switch tier {
        case .demo:
            return PaywallOffer(
                id: "offer-demo",
                tier: .demo,
                eyebrow: "Tanıtım",
                title: "Demo Erişim",
                subtitle: "Başlangıç modülleri zaten açık.",
                price: "Ücretsiz",
                originalPrice: nil,
                badge: nil,
                ctaTitle: "Devam Et",
                primaryFeatures: [],
                secondaryFeatures: [],
                lockedFeatures: [],
                footnote: "",
                comparisonCaption: ""
            )
        case .cirak:
            return PaywallOffer(
                id: moduleTitle.map { "offer-cirak-\($0)" } ?? "offer-cirak",
                tier: .cirak,
                eyebrow: moduleTitle == nil ? "Tattoo Eğitim Sistemi" : "\(moduleTitle!) kilitli",
                title: "Çırak Ol ve Sınırsız Eğitim Modüllerini Aç",
                subtitle: "Görev sistemi, ekipman pratiği ve tüm eğitim akışı tek pakette açılır.",
                price: "₺9.900",
                originalPrice: "₺11.900",
                badge: "%17 İndirim",
                ctaTitle: "ÇIRAK HESABINI AKTİF ET",
                primaryFeatures: [
                    "Tüm eğitim modüllerine erişim",
                    "Görev ve değerlendirme sistemi",
                    "Gerçek ekipman ile pratik",
                    "XP ve rozet ilerlemesi"
                ],
                secondaryFeatures: [
                    "1 yıl erişim",
                    "Ekipman seti ile başlangıç",
                    "Sertifika sistemi",
                    "Kilidi açılan görev akışı"
                ],
                lockedFeatures: [
                    "Mentor destekli değerlendirme",
                    "Canlı yayın dersleri"
                ],
                footnote: "Seti al • hesabını aktif et • eğitime başla",
                comparisonCaption: "Profesyonel dövme kariyerine ilk adım"
            )
        case .kalfa:
            return PaywallOffer(
                id: moduleTitle.map { "offer-kalfa-\($0)" } ?? "offer-kalfa",
                tier: .kalfa,
                eyebrow: moduleTitle == nil ? "Tattoo Eğitim Erişimi" : "\(moduleTitle!) için yükselt",
                title: "Kalfa Üyelik ile Mentor Desteğini Aç",
                subtitle: "Fotoğraflı görevler, topluluk paylaşımı ve mentor destekli gelişim akışı.",
                price: "₺550 / ay",
                originalPrice: nil,
                badge: nil,
                ctaTitle: "KALFA ÜYE OL",
                primaryFeatures: [
                    "Mentor desteği",
                    "Yazılı ve fotoğraflı görevler",
                    "Full topluluk paylaşımı"
                ],
                secondaryFeatures: [
                    "Gerçek eğitime devam",
                    "Haftalık gelişim takibi",
                    "Detaylı değerlendirme alanı"
                ],
                lockedFeatures: [
                    "Seminer, etkinlik ve workshop",
                    "Özel mentor seçimi"
                ],
                footnote: "Yıllık üyelik avantajı ile ilerleme hızlanır",
                comparisonCaption: "Gerçek eğitime devam"
            )
        case .proKalfa:
            return PaywallOffer(
                id: moduleTitle.map { "offer-pro-\($0)" } ?? "offer-pro",
                tier: .proKalfa,
                eyebrow: moduleTitle == nil ? "Tattoo Eğitim Erişimi" : "\(moduleTitle!) için Pro aç",
                title: "Pro Kalfa ile Tam Eğitimin Kilidini Aç",
                subtitle: "Özel seminerler, canlı yayınlar ve kendi mentorunu seçebileceğin ileri seviye erişim.",
                price: "₺2.500 / ay",
                originalPrice: nil,
                badge: "En Güçlü Paket",
                ctaTitle: "PRO OL VE DEVAM ET",
                primaryFeatures: [
                    "Özel seminer ve workshoplar",
                    "Canlı yayın ve içerikler",
                    "Kendi mentorunu seç"
                ],
                secondaryFeatures: [
                    "Profesyonel kariyer akışı",
                    "Öncelikli değerlendirme",
                    "İleri seviye görevler"
                ],
                lockedFeatures: [],
                footnote: "Profesyonel kariyerine başla",
                comparisonCaption: "Tam eğitimin kilidini aç"
            )
        }
    }
}

@Observable
final class AccessManager {
    private let tierKey = "InkAcademy.membershipTier"

    var currentTier: MembershipTier {
        didSet {
            UserDefaults.standard.set(currentTier.rawValue, forKey: tierKey)
        }
    }

    var isProcessingPurchase = false

    init() {
        if
            let rawValue = UserDefaults.standard.string(forKey: tierKey),
            let tier = MembershipTier(rawValue: rawValue)
        {
            currentTier = tier
        } else {
            currentTier = .demo
        }
    }

    var comparisonOffers: [PaywallOffer] {
        [MembershipTier.cirak, .kalfa, .proKalfa].map { PaywallOffer.forTier($0) }
    }

    var recommendedOffer: PaywallOffer? {
        switch currentTier {
        case .demo:
            return .forTier(.cirak)
        case .cirak:
            return .forTier(.kalfa)
        case .kalfa:
            return .forTier(.proKalfa)
        case .proKalfa:
            return nil
        }
    }

    func requiredTier(for module: CourseModule) -> MembershipTier {
        switch module.id {
        case "module-1", "module-2", "module-3":
            return .demo
        case "module-4", "module-5":
            return .cirak
        case "module-6":
            return .kalfa
        case "module-7":
            return .proKalfa
        default:
            return module.isLocked ? .cirak : .demo
        }
    }

    func isUnlocked(_ module: CourseModule) -> Bool {
        currentTier >= requiredTier(for: module)
    }

    func displayedModules(from modules: [CourseModule]) -> [CourseModule] {
        modules.map { module in
            var copy = module
            copy.isLocked = !isUnlocked(module)
            return copy
        }
    }

    func offer(for module: CourseModule) -> PaywallOffer {
        PaywallOffer.forTier(requiredTier(for: module), moduleTitle: module.title)
    }

    func purchase(_ offer: PaywallOffer) async {
        guard !isProcessingPurchase else { return }
        isProcessingPurchase = true
        try? await Task.sleep(for: .milliseconds(900))
        currentTier = max(currentTier, offer.tier)
        isProcessingPurchase = false
    }

    func reset() {
        currentTier = .demo
    }
}
