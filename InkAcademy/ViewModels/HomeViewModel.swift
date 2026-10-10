import Foundation

@Observable
final class HomeViewModel {
    var modules: [CourseModule] = []
    var assignments: [Assignment] = []
    var user: User?
    var isLoading = false
    var errorMessage: String?

    var upcomingLiveSession: LiveSession?
    var suggestedProduct: InkProduct?
    var dailyTaskTitle: String = "Bugün: Hijyen kontrol listesini tamamla"

    private let moduleService: ModuleServiceProtocol
    private let authService: AuthServiceProtocol
    private let assignmentService: AssignmentServiceProtocol
    private let accessManager: AccessManager
    private let userProgress: UserProgressController
    private let ecosystem: EcosystemCatalogServing

    init(
        moduleService: ModuleServiceProtocol,
        authService: AuthServiceProtocol,
        assignmentService: AssignmentServiceProtocol,
        accessManager: AccessManager,
        userProgress: UserProgressController,
        ecosystem: EcosystemCatalogServing
    ) {
        self.moduleService = moduleService
        self.authService = authService
        self.assignmentService = assignmentService
        self.accessManager = accessManager
        self.userProgress = userProgress
        self.ecosystem = ecosystem
    }

    // MARK: - Progress (ders kataloğu)

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

    // MARK: - XP / seviye (paylaşılan mock ilerleme)

    var studentLevel: String {
        userProgress.progress.currentLevel.title
    }

    var studentLevelIcon: String {
        userProgress.progress.currentLevel.icon
    }

    var experiencePoints: Int {
        userProgress.progress.xp
    }

    var progressController: UserProgressController {
        userProgress
    }

    var currentLesson: (module: CourseModule, lesson: Lesson)? {
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

    var pendingAssignmentCount: Int {
        assignments.filter { $0.status == .pending }.count
    }

    var nextPendingAssignment: Assignment? {
        assignments
            .filter { $0.status == .pending }
            .sorted { $0.dueDate < $1.dueDate }
            .first
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
        userProgress.syncUserId(authService.currentUser?.id ?? "local-demo-user")

        async let modulesResult = moduleService.fetchModules()
        async let assignmentsResult = assignmentService.fetchAssignments()
        async let liveResult = ecosystem.fetchLiveSessions()
        async let productsResult = ecosystem.fetchProducts()

        do {
            modules = try await modulesResult
        } catch {
            errorMessage = error.localizedDescription
        }

        do {
            assignments = try await assignmentsResult
        } catch {
            // non-fatal
        }

        let live = await liveResult
        upcomingLiveSession = live.first

        let products = await productsResult
        suggestedProduct = products.first { $0.category == .needle } ?? products.first

        isLoading = false
    }
}
