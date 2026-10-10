import Foundation

/// XP / seviye / rozet kapıları için sabit mini iz — Supabase bağlanınca gerçek modül listesiyle değiştirilebilir.
enum ProfileDemoCatalog {

    static let modIntro = "prof_mod_giris"
    static let modHygiene = "prof_mod_hijyen"
    static let modLinework = "prof_mod_linework"
    static let modStencil = "prof_mod_stencil"
    static let modShading = "prof_mod_shading"
    static let modAdvanced = "prof_mod_advanced"

    static let lesIntro = "prof_les_g1"
    static let lesHygiene = "prof_les_h1"
    static let lesLinework = "prof_les_l1"
    static let lesStencil1 = "prof_les_s1"
    static let lesStencil2 = "prof_les_s2"
    static let lesShade = "prof_les_sh1"
    static let lesAdv1 = "prof_les_a1"
    static let lesAdv2 = "prof_les_a2"

    static var gateModules: [CourseModule] {
        [
            CourseModule(
                id: modIntro,
                title: "Giriş & Stüdyo Kültürü",
                description: "Eğitim disiplini ve temel kavramlar.",
                imageURL: nil,
                lessons: [
                    Lesson(
                        id: lesIntro,
                        title: "Stüdyoya giriş",
                        videoURL: nil,
                        duration: 720,
                        order: 1,
                        isCompleted: false,
                        description: "Kurallar ve akış.",
                        xpReward: 35,
                        relatedProductIds: [],
                        qrCodeValue: "INK-LESSON-LINE-001",
                        hasQuiz: false,
                        hasAssignment: false
                    )
                ],
                isLocked: false,
                levelRequirementTitle: "Acemi",
                xpReward: 80,
                isRequired: true,
                isAdvanced: false,
                relatedProductIds: [],
                practiceTaskIds: []
            ),
            CourseModule(
                id: modHygiene,
                title: "Hijyen ve Güvenlik",
                description: "Enfeksiyon kontrolü ve alan hazırlığı.",
                imageURL: nil,
                lessons: [
                    Lesson(
                        id: lesHygiene,
                        title: "Hijyen protokolü",
                        videoURL: nil,
                        duration: 1_080,
                        order: 1,
                        isCompleted: false,
                        description: "PPE ve sterilizasyon.",
                        xpReward: 45,
                        relatedProductIds: ["prod_hygiene_kit"],
                        qrCodeValue: "INK-BOOK-HYGIENE-01",
                        hasQuiz: true,
                        hasAssignment: false
                    )
                ],
                isLocked: false,
                levelRequirementTitle: "Acemi",
                xpReward: 150,
                isRequired: true,
                isAdvanced: false,
                relatedProductIds: ["prod_hygiene_kit"],
                practiceTaskIds: []
            ),
            CourseModule(
                id: modLinework,
                title: "Linework",
                description: "Hat güvenliği ve kontrol.",
                imageURL: nil,
                lessons: [
                    Lesson(
                        id: lesLinework,
                        title: "Çizgi egzersizi",
                        videoURL: nil,
                        duration: 900,
                        order: 1,
                        isCompleted: false,
                        description: "İğne açısı ve hız.",
                        xpReward: 50,
                        relatedProductIds: ["prod_needle_0807rl"],
                        qrCodeValue: nil,
                        hasQuiz: false,
                        hasAssignment: true
                    )
                ],
                isLocked: false,
                levelRequirementTitle: "Çırak",
                xpReward: 140,
                isRequired: true,
                isAdvanced: false,
                relatedProductIds: ["prod_needle_0807rl"],
                practiceTaskIds: ["prac_linework_1"]
            ),
            CourseModule(
                id: modStencil,
                title: "Stencil",
                description: "Transfer ve hizalama.",
                imageURL: nil,
                lessons: [
                    Lesson(id: lesStencil1, title: "Stencil hazırlığı", videoURL: nil, duration: 840, order: 1, isCompleted: false, description: "Cilt ve transfer.", xpReward: 40),
                    Lesson(id: lesStencil2, title: "Hizalama", videoURL: nil, duration: 960, order: 2, isCompleted: false, description: "Eğriler.", xpReward: 45)
                ],
                isLocked: false,
                levelRequirementTitle: "Çırak",
                xpReward: 160,
                isRequired: true,
                isAdvanced: false,
                relatedProductIds: ["prod_stencil_transfer"],
                practiceTaskIds: ["prac_stencil_1"]
            ),
            CourseModule(
                id: modShading,
                title: "Shading",
                description: "Ton ve packing.",
                imageURL: nil,
                lessons: [
                    Lesson(
                        id: lesShade,
                        title: "Gölgeleme temelleri",
                        videoURL: nil,
                        duration: 1_320,
                        order: 1,
                        isCompleted: false,
                        description: "Whip ve packing.",
                        xpReward: 55,
                        relatedProductIds: ["prod_gray_wash"],
                        hasQuiz: true,
                        hasAssignment: false
                    )
                ],
                isLocked: false,
                levelRequirementTitle: "Çırak",
                xpReward: 180,
                isRequired: true,
                isAdvanced: false,
                relatedProductIds: ["prod_gray_wash"],
                practiceTaskIds: ["prac_shade_1"]
            ),
            CourseModule(
                id: modAdvanced,
                title: "İleri Stüdyo",
                description: "Uzun seans ve plan.",
                imageURL: nil,
                lessons: [
                    Lesson(id: lesAdv1, title: "Seans planı", videoURL: nil, duration: 1_500, order: 1, isCompleted: false, description: "Zaman yönetimi.", xpReward: 60),
                    Lesson(id: lesAdv2, title: "Bitiriş", videoURL: nil, duration: 1_200, order: 2, isCompleted: false, description: "Fotoğraf ve bakım.", xpReward: 55)
                ],
                isLocked: false,
                levelRequirementTitle: "Kalfa",
                xpReward: 320,
                isRequired: false,
                isAdvanced: true,
                relatedProductIds: ["prod_machine_coil"],
                practiceTaskIds: []
            )
        ]
    }
}
