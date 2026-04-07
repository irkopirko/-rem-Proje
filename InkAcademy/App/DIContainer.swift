import Foundation

@Observable
final class DIContainer {
    let authService: AuthServiceProtocol
    let moduleService: ModuleServiceProtocol
    let assignmentService: AssignmentServiceProtocol
    let qrService: QRServiceProtocol
    let accessManager: AccessManager
    let router: AppRouter

    // MARK: - Toggle: set to `true` to use Supabase, `false` for mock data
    static let useLiveBackend = true

    init(
        authService: AuthServiceProtocol = DIContainer.useLiveBackend ? SupabaseAuthService() : MockAuthService(),
        moduleService: ModuleServiceProtocol = DIContainer.useLiveBackend ? SupabaseModuleService() : MockModuleService(),
        assignmentService: AssignmentServiceProtocol = DIContainer.useLiveBackend ? SupabaseAssignmentService() : MockAssignmentService(),
        qrService: QRServiceProtocol = DIContainer.useLiveBackend ? SupabaseQRService() : MockQRService(),
        accessManager: AccessManager = AccessManager(),
        router: AppRouter = AppRouter()
    ) {
        self.authService = authService
        self.moduleService = moduleService
        self.assignmentService = assignmentService
        self.qrService = qrService
        self.accessManager = accessManager
        self.router = router
    }

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authService: authService, router: router)
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            moduleService: moduleService,
            authService: authService,
            assignmentService: assignmentService,
            accessManager: accessManager
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
            moduleService: moduleService,
            assignmentService: assignmentService,
            router: router
        )
    }
}
