import Foundation

@Observable
final class HomeViewModel {
    var modules: [TrainingModule] = []
    var assignments: [Assignment] = []
    var user: User?
    var isLoading = false
    var errorMessage: String?

    private let moduleService: ModuleServiceProtocol
    private let authService: AuthServiceProtocol
    private let assignmentService: AssignmentServiceProtocol
    private let accessManager: AccessManager

    init(
        moduleService: ModuleServiceProtocol,
        authService: AuthServiceProtocol,
        assignmentService: AssignmentServiceProtocol,
        accessManager: AccessManager
    ) {
        self.moduleService = moduleService
        self.authService = authService
        self.assignmentService = assignmentService
        self.accessManager = accessManager
    }

    // MARK: - Computed — Progress

    var totalLessons: Int {
        modules.reduce(0) { $0 + $1.lessons.count }
    }

    var completedLessons: Int {
        modules.reduce(0) { $0 + $1.completedLessonsCount }
    }

    var completedModules: Int {
        modules.filter { $0.progressPercent >= 1.0 }.count
    }

    var overallProgress: Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons)
    }

    // MARK: - Computed — Student Level

    var studentLevel: String {
        StudentLevel.forCompletedLessons(completedLessons).title
    }

    var studentLevelIcon: String {
        StudentLevel.forCompletedLessons(completedLessons).icon
    }

    // MARK: - Computed — Current Lesson

    var currentLesson: (module: TrainingModule, lesson: Lesson)? {
        for module in modules where accessManager.isUnlocked(module) {
            if let lesson = module.lessons.sorted(by: { $0.order < $1.order }).first(where: { !$0.isCompleted }) {
                return (module, lesson)
            }
        }
        return nil
    }

    var lockedModuleCount: Int {
        modules.filter { !accessManager.isUnlocked($0) }.count
    }

    var currentTierTitle: String {
        accessManager.currentTier.marketingTitle
    }

    var recommendedOffer: PaywallOffer? {
        accessManager.recommendedOffer
    }

    // MARK: - Computed — Assignments

    var pendingAssignmentCount: Int {
        assignments.filter { $0.status == .pending }.count
    }

    var nextPendingAssignment: Assignment? {
        assignments
            .filter { $0.status == .pending }
            .sorted { $0.dueDate < $1.dueDate }
            .first
    }

    var experiencePoints: Int {
        (completedLessons * 120) + (completedModules * 300) + (pendingAssignmentCount * 20)
    }

    var latestFeedback: (feedback: Feedback, assignmentTitle: String)? {
        let reviewed = assignments.filter { $0.feedback != nil }
            .sorted { ($0.feedback?.date ?? .distantPast) > ($1.feedback?.date ?? .distantPast) }
        guard let top = reviewed.first, let fb = top.feedback else { return nil }
        return (fb, top.title)
    }

    // MARK: - Actions

    func makeLessonDetailViewModel(for lesson: Lesson) -> LessonDetailViewModel {
        LessonDetailViewModel(
            lesson: lesson,
            moduleService: moduleService,
            assignmentService: assignmentService
        )
    }

    func loadData() async {
        isLoading = true
        user = authService.currentUser

        async let modulesResult = moduleService.fetchModules()
        async let assignmentsResult = assignmentService.fetchAssignments()

        do {
            modules = try await modulesResult
        } catch {
            errorMessage = error.localizedDescription
        }

        do {
            assignments = try await assignmentsResult
        } catch {
            // Assignments error non-fatal for home
        }

        isLoading = false
    }
}
