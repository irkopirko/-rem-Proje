import Foundation

@Observable
@MainActor
final class AccountSettingsViewModel {
    var userName: String = ""
    var email: String = ""
    var username: String = ""
    var avatarURL: URL?
    var isLoading = false
    var errorMessage: String?
    var deleteAccountError: String?

    var completedModulesCount: Int = 0
    var completedLessonsCount: Int = 0
    var pendingHomeworkCount: Int = 0
    var submittedHomeworkCount: Int = 0
    var weeklyStreakDays: Int = 0

    let notificationPreferences: NotificationPreferencesStore

    private let authService: AuthServiceProtocol
    private let router: AppRouter
    private let userProgress: UserProgressController
    private let assignmentService: AssignmentServiceProtocol

    init(
        authService: AuthServiceProtocol,
        router: AppRouter,
        userProgress: UserProgressController,
        assignmentService: AssignmentServiceProtocol,
        notificationPreferences: NotificationPreferencesStore = NotificationPreferencesStore()
    ) {
        self.authService = authService
        self.router = router
        self.userProgress = userProgress
        self.assignmentService = assignmentService
        self.notificationPreferences = notificationPreferences
    }

    var initials: String {
        let parts = userName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    var levelTitle: String {
        userProgress.progress.currentLevel.title
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let uid = authService.currentUser?.id ?? "local-demo-user"
        userProgress.syncUserId(uid)

        if let user = authService.currentUser {
            userName = user.name
            email = user.email
            avatarURL = user.avatarURL
            username = Self.deriveUsername(from: user)
        } else {
            userName = "Demo Öğrenci"
            email = "demo@inkakademi.com"
            username = "demo_ogrenci"
        }

        completedModulesCount = userProgress.progress.completedModuleIds.count
        completedLessonsCount = userProgress.progress.completedLessonIds.count
        weeklyStreakDays = WeeklyActivityTracker.currentStreakDays

        do {
            let assignments = try await assignmentService.fetchAssignments()
            pendingHomeworkCount = assignments.filter { $0.status == .pending }.count
            submittedHomeworkCount = assignments.filter {
                $0.status == .submitted || $0.status == .reviewed || $0.status == .revisionRequested
            }.count
        } catch {
            pendingHomeworkCount = 0
            submittedHomeworkCount = 0
        }

        try? await Task.sleep(for: .milliseconds(150))
    }

    func logout() async {
        await authService.logout()
        router.isAuthenticated = false
    }

    func deleteAccount() async -> Bool {
        deleteAccountError = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.requestAccountDeletion()
            router.isAuthenticated = false
            return true
        } catch {
            deleteAccountError = error.localizedDescription
            return false
        }
    }

    private static func deriveUsername(from user: User) -> String {
        if let local = user.email.split(separator: "@").first, !local.isEmpty {
            return String(local).lowercased()
        }
        return user.name
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }
}
