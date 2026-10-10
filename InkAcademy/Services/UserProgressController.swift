import Foundation

/// Paylaşılan XP / seviye durumu — profil ve ana sayfa aynı anlık görünümü kullanır (mock).
@Observable
final class UserProgressController {
    private(set) var progress: UserProgress

    init(userId: String = "local-demo-user") {
        self.progress = UserProgress(
            userId: userId,
            xp: 40,
            completedLessonIds: ["lesson-1-1"],
            completedModuleIds: [],
            earnedBadgeIds: [BadgeID.ilkDers.rawValue],
            modules: ProfileDemoCatalog.gateModules
        )
    }

    var gateModules: [CourseModule] { ProfileDemoCatalog.gateModules }

    func syncUserId(_ userId: String) {
        if progress.userId != userId {
            progress = UserProgress(
                userId: userId,
                xp: progress.xp,
                completedLessonIds: progress.completedLessonIds,
                completedModuleIds: progress.completedModuleIds,
                earnedBadgeIds: progress.earnedBadgeIds,
                modules: gateModules
            )
        }
    }

    func apply(_ update: (inout UserProgress) -> Void) {
        var p = progress
        update(&p)
        p.recalculateLevel(modules: gateModules)
        progress = p
    }
}
