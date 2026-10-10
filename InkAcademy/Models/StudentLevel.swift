import Foundation
import SwiftUI

/// Dövmeci seviye katmanı — XP bantları + modül / rozet şartları `calculateLevel` ile birleşir.
struct StudentLevel: Equatable, Hashable {
    let title: String
    let icon: String
    let minXP: Int
    /// Üst XP eşiği (son seviye için `Int.max`).
    let nextLevelXP: Int
    /// Bu seviye için üst XP tavanı (görsel metinlerde).
    let maxXP: Int
    let description: String
    /// Seviyeye çıkmak için özet şart metni (XP dışı koşullar dahil).
    let requirementText: String
    let colorName: String
    let levelColor: Color

    static let tierAcemi = StudentLevel(
        title: "Acemi",
        icon: "leaf.fill",
        minXP: 0,
        nextLevelXP: 500,
        maxXP: 499,
        description: "Temelleri öğreniyorsun; video, pratik ve quiz ile ilerleme kaydediyorsun.",
        requirementText: "0–499 XP aralığında kalırsın; sonraki adım için 500 XP hedefle.",
        colorName: "sage",
        levelColor: .inkSage
    )

    static let tierCirak = StudentLevel(
        title: "Çırak",
        icon: "flame.fill",
        minXP: 500,
        nextLevelXP: 1_000,
        maxXP: 999,
        description: "Ekipman ve hijyen ritmini oturtuyorsun; linework ve stencil pratiği artıyor.",
        requirementText: "500–999 XP; temel modül şartı Kalfa’ya geçişte devreye girer.",
        colorName: "teal",
        levelColor: .inkTeal
    )

    static let tierKalfa = StudentLevel(
        title: "Kalfa",
        icon: "star.fill",
        minXP: 1_000,
        nextLevelXP: 2_000,
        maxXP: 1_999,
        description: "Temel modüller tamamlandı; shading, renk ve müşteri süreçlerine geçiş.",
        requirementText: "1000–1999 XP + tüm zorunlu temel modüllerin bitmiş olması gerekir.",
        colorName: "accent",
        levelColor: .inkAccent
    )

    static let tierUsta = StudentLevel(
        title: "Usta",
        icon: "crown.fill",
        minXP: 2_000,
        nextLevelXP: Int.max,
        maxXP: Int.max,
        description: "İleri modül ve seçilmiş rozetlerle profesyonel çizgiye ulaştın.",
        requirementText: "2000+ XP + ileri modül + “Kalfa Adayı” ve “Usta Yolu” rozetleri gerekir.",
        colorName: "warning",
        levelColor: .inkWarning
    )

    static func calculateLevel(
        xp: Int,
        completedRequiredModules: Bool,
        completedAdvancedModules: Bool,
        earnedBadgeIds: Set<String>
    ) -> StudentLevel {
        let raw = rawTierIndex(forXP: xp)
        var idx = raw

        if idx >= 2, !completedRequiredModules {
            idx = min(idx, 1)
        }

        let ustaBadgeOK = earnedBadgeIds.contains(BadgeID.kalfaAdayi.rawValue)
            && earnedBadgeIds.contains(BadgeID.ustaYolu.rawValue)
        if idx >= 3 {
            let eligible = xp >= 2_000 && completedAdvancedModules && ustaBadgeOK
            if !eligible {
                idx = min(idx, 2)
            }
        }

        switch idx {
        case 0: return .tierAcemi
        case 1: return .tierCirak
        case 2: return .tierKalfa
        default: return .tierUsta
        }
    }

    private static func rawTierIndex(forXP xp: Int) -> Int {
        switch xp {
        case ..<500: return 0
        case ..<1_000: return 1
        case ..<2_000: return 2
        default: return 3
        }
    }

    /// Ana sayfa gibi yerlerde ders sayısına göre yaklaşık rozet seviyesi (XP verisi yoksa).
    static func forCompletedLessons(_ completedLessons: Int) -> StudentLevel {
        switch completedLessons {
        case 0:
            return .tierAcemi
        case 1...3:
            return .tierCirak
        case 4...11:
            return .tierKalfa
        default:
            return .tierUsta
        }
    }
}
