import Foundation

struct UserProgress: Identifiable, Equatable {
    let id: String
    var userId: String
    var xp: Int
    var completedLessonIds: [String]
    var completedModuleIds: [String]
    var earnedBadgeIds: [String]
    var currentLevel: StudentLevel
    var progressToNextLevel: Double

    init(
        userId: String,
        xp: Int = 0,
        completedLessonIds: [String] = [],
        completedModuleIds: [String] = [],
        earnedBadgeIds: [String] = [],
        modules: [CourseModule] = []
    ) {
        self.id = userId
        self.userId = userId
        self.xp = xp
        self.completedLessonIds = completedLessonIds
        self.completedModuleIds = completedModuleIds
        self.earnedBadgeIds = earnedBadgeIds
        self.currentLevel = Self.computeLevel(
            xp: xp,
            completedLessonIds: completedLessonIds,
            completedModuleIds: completedModuleIds,
            earnedBadgeIds: Set(earnedBadgeIds),
            modules: modules
        )
        self.progressToNextLevel = Self.computeProgressToNextLevel(
            xp: xp,
            level: self.currentLevel
        )
    }

    mutating func completeLesson(lessonId: String, xpGain: Int, modules: [CourseModule]) {
        guard !completedLessonIds.contains(lessonId) else { return }
        completedLessonIds.append(lessonId)
        xp += xpGain
        recalculateLevel(modules: modules)
    }

    mutating func completeModule(moduleId: String, xpGain: Int, modules: [CourseModule]) {
        guard !completedModuleIds.contains(moduleId) else { return }
        completedModuleIds.append(moduleId)
        xp += xpGain
        recalculateLevel(modules: modules)
    }

    mutating func earnBadge(_ badge: Badge, modules: [CourseModule]) {
        guard !earnedBadgeIds.contains(badge.id) else { return }
        earnedBadgeIds.append(badge.id)
        xp += badge.xpReward
        recalculateLevel(modules: modules)
    }

    mutating func recalculateLevel(modules: [CourseModule]) {
        currentLevel = Self.computeLevel(
            xp: xp,
            completedLessonIds: completedLessonIds,
            completedModuleIds: completedModuleIds,
            earnedBadgeIds: Set(earnedBadgeIds),
            modules: modules
        )
        progressToNextLevel = calculateProgressToNextLevel()
    }

    @discardableResult
    mutating func calculateProgressToNextLevel() -> Double {
        let v = Self.computeProgressToNextLevel(xp: xp, level: currentLevel)
        progressToNextLevel = v
        return v
    }

    func remainingXPToNextLevel() -> Int {
        guard currentLevel.nextLevelXP != Int.max else { return 0 }
        return max(0, currentLevel.nextLevelXP - xp)
    }

    // MARK: - Private

    private static func computeLevel(
        xp: Int,
        completedLessonIds: [String],
        completedModuleIds: [String],
        earnedBadgeIds: Set<String>,
        modules: [CourseModule]
    ) -> StudentLevel {
        let lessonDone = Set(completedLessonIds)
        let moduleDone = Set(completedModuleIds)

        let requiredBasics = modules.filter { $0.isRequired && !$0.isAdvanced }
        let completedRequiredModules = requiredBasics.isEmpty
            ? false
            : requiredBasics.allSatisfy { isModuleComplete($0, lessonDone: lessonDone, moduleDone: moduleDone) }

        let completedAdvancedModules = modules.contains {
            $0.isAdvanced && isModuleComplete($0, lessonDone: lessonDone, moduleDone: moduleDone)
        }

        return StudentLevel.calculateLevel(
            xp: xp,
            completedRequiredModules: completedRequiredModules,
            completedAdvancedModules: completedAdvancedModules,
            earnedBadgeIds: earnedBadgeIds
        )
    }

    private static func isModuleComplete(
        _ module: CourseModule,
        lessonDone: Set<String>,
        moduleDone: Set<String>
    ) -> Bool {
        if moduleDone.contains(module.id) { return true }
        guard !module.lessons.isEmpty else { return false }
        return module.lessons.allSatisfy { lessonDone.contains($0.id) }
    }

    private static func computeProgressToNextLevel(xp: Int, level: StudentLevel) -> Double {
        guard level.nextLevelXP != Int.max else { return 1 }
        let span = Double(level.nextLevelXP - level.minXP)
        guard span > 0 else { return 1 }
        let t = Double(xp - level.minXP) / span
        return min(max(t, 0), 1)
    }
}
