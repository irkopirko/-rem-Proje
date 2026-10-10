import Foundation

@Observable
final class DIContainer {
    let authService: AuthServiceProtocol
    let moduleService: ModuleServiceProtocol
    let assignmentService: AssignmentServiceProtocol
    let qrService: QRServiceProtocol
    let accessManager: AccessManager
    let router: AppRouter
    let ecosystemCatalog: EcosystemCatalogServing
    let userProgress: UserProgressController
    let notificationPreferences: NotificationPreferencesStore

    // MARK: - Toggle: set to `true` to use Supabase, `false` for mock data
    static let useLiveBackend = true

    /// Geçici: giriş ekranını atla, doğrudan ana uygulamayı aç.
    /// Canlıya almadan önce `false` yapın.
    static let skipLoginForDevelopment = true

    init(
        authService: AuthServiceProtocol = DIContainer.useLiveBackend ? SupabaseAuthService() : MockAuthService(),
        // Modül listesi şimdilik yerel mock veriden gelir (Dövmeye Giriş, Dotwork, Linework).
        moduleService: ModuleServiceProtocol = MockModuleService(),
        assignmentService: AssignmentServiceProtocol = DIContainer.useLiveBackend ? SupabaseAssignmentService() : MockAssignmentService(),
        qrService: QRServiceProtocol = DIContainer.useLiveBackend ? SupabaseQRService() : MockQRService(),
        accessManager: AccessManager = AccessManager(),
        router: AppRouter = AppRouter(),
        ecosystemCatalog: EcosystemCatalogServing = MockEcosystemCatalogService(),
        userProgress: UserProgressController = UserProgressController(),
        notificationPreferences: NotificationPreferencesStore = NotificationPreferencesStore()
    ) {
        self.authService = authService
        self.moduleService = moduleService
        self.assignmentService = assignmentService
        self.qrService = qrService
        self.accessManager = accessManager
        self.router = router
        self.ecosystemCatalog = ecosystemCatalog
        self.userProgress = userProgress
        self.notificationPreferences = notificationPreferences

        if Self.skipLoginForDevelopment {
            self.router.isAuthenticated = true
        }
    }

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authService: authService, router: router)
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            moduleService: moduleService,
            authService: authService,
            assignmentService: assignmentService,
            accessManager: accessManager,
            userProgress: userProgress,
            ecosystem: ecosystemCatalog
        )
    }

    func makeModulesViewModel() -> ModulesViewModel {
        ModulesViewModel(
            moduleService: moduleService,
            qrService: qrService,
            assignmentService: assignmentService,
            accessManager: accessManager
        )
    }

    func makeAssignmentsViewModel() -> AssignmentsViewModel {
        AssignmentsViewModel(assignmentService: assignmentService)
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            authService: authService,
            router: router,
            userProgress: userProgress,
            ecosystem: ecosystemCatalog
        )
    }

    func makeAccountSettingsViewModel() -> AccountSettingsViewModel {
        AccountSettingsViewModel(
            authService: authService,
            router: router,
            userProgress: userProgress,
            assignmentService: assignmentService,
            notificationPreferences: notificationPreferences
        )
    }
}
