import Foundation

@Observable
@MainActor
final class ProfileViewModel {

    var userName: String = ""
    var email: String = ""
    var badges: [Badge] = []
    var certificates: [Certificate] = []
    var isOwnProfile: Bool = true
    var isLoading: Bool = false

    var quizAverageDisplay: String { "8.4 / 10" }

    var instructorComment: String {
        "Mock: Eğitmen notu — linework stabil, packing’te tempo biraz yüksek. Bir sonraki modülde gölge geçişlerine odaklan."
    }

    private let authService: AuthServiceProtocol
    private let router: AppRouter
    private let userProgress: UserProgressController
    private let ecosystem: EcosystemCatalogServing

    var progress: UserProgress { userProgress.progress }

    var gateModules: [CourseModule] { userProgress.gateModules }

    init(
        authService: AuthServiceProtocol,
        router: AppRouter,
        userProgress: UserProgressController,
        ecosystem: EcosystemCatalogServing,
        isOwnProfile: Bool = true
    ) {
        self.authService = authService
        self.router = router
        self.userProgress = userProgress
        self.ecosystem = ecosystem
        self.isOwnProfile = isOwnProfile
    }

    var initials: String {
        let parts = userName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    func visibleXPText() -> String {
        guard isOwnProfile else { return "" }
        return "\(progress.xp) XP"
    }

    func levelTitle() -> String {
        progress.currentLevel.title
    }

    func levelDescription() -> String {
        progress.currentLevel.description
    }

    func remainingXPHint() -> String {
        let rem = progress.remainingXPToNextLevel()
        if progress.currentLevel.nextLevelXP == Int.max {
            return "Sonraki seviye için kalan XP: — (Usta)"
        }
        return "Sonraki seviye için kalan XP: \(rem)"
    }

    func supplementalGateHint() -> String? {
        let xp = progress.xp
        let title = progress.currentLevel.title
        if xp >= 1_000, title == "Çırak" {
            return "Kalfa için tüm temel modülleri tamamlaman gerekir (XP tek başına yetmez)."
        }
        if xp >= 2_000, title == "Kalfa" {
            return "Usta için ileri modülü ve “Kalfa Adayı” ile “Usta Yolu” rozetlerini tamamlaman gerekir."
        }
        return nil
    }

    func loadMockProfile() async {
        let uid = authService.currentUser?.id ?? "local-demo-user"
        userProgress.syncUserId(uid)
        userName = authService.currentUser?.name ?? "Demo Öğrenci"
        email = authService.currentUser?.email ?? "demo@inkakademi.com"
        certificates = await ecosystem.fetchCertificates()
        syncBadgesAndAutoRewards()
    }

    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        try? await Task.sleep(for: .milliseconds(200))
        await loadMockProfile()
    }

    func completeDemoLesson() {
        let flat = gateModules.flatMap(\.lessons).sorted { $0.order < $1.order }
        guard let next = flat.first(where: { !progress.completedLessonIds.contains($0.id) }) else { return }
        userProgress.apply { p in
            p.completeLesson(lessonId: next.id, xpGain: next.xpReward, modules: gateModules)
        }
        syncBadgesAndAutoRewards()
    }

    func completeDemoModule() {
        guard let mod = gateModules.first(where: { !isModuleFullyTracked($0) }) else { return }
        userProgress.apply { p in
            for les in mod.lessons where !p.completedLessonIds.contains(les.id) {
                p.completeLesson(lessonId: les.id, xpGain: les.xpReward, modules: gateModules)
            }
            if !p.completedModuleIds.contains(mod.id) {
                p.completeModule(moduleId: mod.id, xpGain: mod.xpReward, modules: gateModules)
            }
        }
        syncBadgesAndAutoRewards()
    }

    private func isModuleFullyTracked(_ m: CourseModule) -> Bool {
        let l = Set(userProgress.progress.completedLessonIds)
        let md = Set(userProgress.progress.completedModuleIds)
        if md.contains(m.id) { return true }
        return !m.lessons.isEmpty && m.lessons.allSatisfy { l.contains($0.id) }
    }

    func earnDemoBadge() {
        guard let badge = Badge.catalog.first(where: { !progress.earnedBadgeIds.contains($0.id) }) else { return }
        userProgress.apply { p in
            p.earnBadge(badge, modules: gateModules)
        }
        syncBadgesAndAutoRewards()
    }

    func logout() async {
        await authService.logout()
        router.isAuthenticated = false
    }

    // MARK: - Private

    private func syncBadgesAndAutoRewards() {
        var changed = true
        while changed {
            changed = false
            for def in Badge.catalog where !userProgress.progress.earnedBadgeIds.contains(def.id) {
                guard autoEarnEligible(def) else { continue }
                userProgress.apply { p in
                    p.earnBadge(def, modules: gateModules)
                }
                changed = true
            }
        }
        badges = Badge.catalog.map { b in
            var c = b
            c.isEarned = userProgress.progress.earnedBadgeIds.contains(b.id)
            return c
        }
    }

    private func autoEarnEligible(_ badge: Badge) -> Bool {
        let l = Set(progress.completedLessonIds)
        let m = Set(progress.completedModuleIds)
        let basics: Set<String> = [
            ProfileDemoCatalog.modIntro,
            ProfileDemoCatalog.modHygiene,
            ProfileDemoCatalog.modLinework,
            ProfileDemoCatalog.modStencil,
            ProfileDemoCatalog.modShading
        ]

        switch badge.id {
        case BadgeID.ilkDers.rawValue:
            return !l.isEmpty
        case BadgeID.hijyenTemeli.rawValue:
            return m.contains(ProfileDemoCatalog.modHygiene) || moduleFullyDone(ProfileDemoCatalog.modHygiene, l: l, m: m)
        case BadgeID.lineworkBaslangici.rawValue:
            return l.contains(ProfileDemoCatalog.lesLinework) || m.contains(ProfileDemoCatalog.modLinework)
        case BadgeID.stencilCalismasi.rawValue:
            return m.contains(ProfileDemoCatalog.modStencil) || moduleFullyDone(ProfileDemoCatalog.modStencil, l: l, m: m)
        case BadgeID.golgelemeCiragi.rawValue:
            return l.contains(ProfileDemoCatalog.lesShade) || m.contains(ProfileDemoCatalog.modShading)
        case BadgeID.kalfaAdayi.rawValue:
            return basics.allSatisfy { mid in
                m.contains(mid) || moduleFullyDone(mid, l: l, m: m)
            }
        case BadgeID.ustaYolu.rawValue:
            return m.contains(ProfileDemoCatalog.modAdvanced) || moduleFullyDone(ProfileDemoCatalog.modAdvanced, l: l, m: m)
        default:
            return false
        }
    }

    private func moduleFullyDone(_ moduleId: String, l: Set<String>, m: Set<String>) -> Bool {
        guard let mod = gateModules.first(where: { $0.id == moduleId }) else { return false }
        if m.contains(mod.id) { return true }
        return !mod.lessons.isEmpty && mod.lessons.allSatisfy { l.contains($0.id) }
    }
}
