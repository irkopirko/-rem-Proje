import Foundation

@Observable
final class ProfileViewModel {

    // MARK: - State

    var user: User?
    var modules: [TrainingModule] = []
    var assignments: [Assignment] = []
    var isLoading = false

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let moduleService: ModuleServiceProtocol
    private let assignmentService: AssignmentServiceProtocol
    private let router: AppRouter

    init(
        authService: AuthServiceProtocol,
        moduleService: ModuleServiceProtocol,
        assignmentService: AssignmentServiceProtocol,
        router: AppRouter
    ) {
        self.authService = authService
        self.moduleService = moduleService
        self.assignmentService = assignmentService
        self.router = router
    }

    // MARK: - Computed — Identity

    var displayName: String {
        user?.name ?? "Öğrenci"
    }

    var email: String {
        user?.email ?? ""
    }

    var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    // MARK: - Computed — Student Level

    var studentLevel: String {
        StudentLevel.forCompletedLessons(completedLessons).title
    }

    var studentLevelIcon: String {
        StudentLevel.forCompletedLessons(completedLessons).icon
    }

    // MARK: - Computed — Modules & Lessons

    var totalModules: Int { modules.count }

    var completedModules: Int {
        modules.filter { $0.progressPercent >= 1.0 }.count
    }

    var totalLessons: Int {
        modules.reduce(0) { $0 + $1.lessons.count }
    }

    var completedLessons: Int {
        modules.reduce(0) { $0 + $1.completedLessonsCount }
    }

    var overallProgress: Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons)
    }

    // MARK: - Computed — Assignments

    var submittedAssignments: Int {
        assignments.filter { $0.status != .pending }.count
    }

    var reviewedAssignments: Int {
        assignments.filter { $0.status == .reviewed }.count
    }

    var totalAssignments: Int { assignments.count }

    // MARK: - Computed — Quiz Score Summary

    /// Average feedback rating across reviewed assignments (proxy for quiz performance)
    var averageScore: Double {
        let scored = assignments.compactMap { $0.feedback?.rating }
        guard !scored.isEmpty else { return 0 }
        return Double(scored.reduce(0, +)) / Double(scored.count)
    }

    var averageScoreFormatted: String {
        averageScore > 0 ? String(format: "%.1f/10", averageScore) : "—"
    }

    var experiencePoints: Int {
        (completedLessons * 120) + (completedModules * 300) + (reviewedAssignments * 80)
    }

    // MARK: - Actions

    func loadProfile() async {
        isLoading = true
        user = authService.currentUser

        async let modulesResult = moduleService.fetchModules()
        async let assignmentsResult = assignmentService.fetchAssignments()

        do { modules = try await modulesResult } catch { }
        do { assignments = try await assignmentsResult } catch { }

        isLoading = false
    }

    func logout() async {
        await authService.logout()
        router.isAuthenticated = false
    }
}
