import Foundation

@Observable
final class DIContainer {
    let authService: AuthServiceProtocol
    let api: InkAPIClient
    let router: AppRouter

    private(set) var sessionUser: User?

    init(
        authService: AuthServiceProtocol? = nil,
        api: InkAPIClient = .shared,
        router: AppRouter = AppRouter()
    ) {
        self.api = api
        self.router = router
        if APIConfiguration.usesMockBackend {
            self.authService = authService ?? MockAuthService()
        } else if APIConfiguration.usesLocalAuth {
            self.authService = authService ?? LocalAuthService()
        } else {
            self.authService = authService ?? InkAuthService()
        }
        NotificationCenter.default.addObserver(forName: .inkSessionExpired, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.handleSessionExpired() }
        }
    }

    func bootstrapSession() async {
        guard !APIConfiguration.usesMockBackend,
              KeychainTokenStore.accessToken() != nil,
              let live = authService as? InkAuthService else { return }
        do {
            let user = try await withThrowingTaskGroup(of: User.self) { group in
                group.addTask { try await live.fetchMe() }
                group.addTask {
                    try await Task.sleep(for: .seconds(8))
                    throw CancellationError()
                }
                guard let first = try await group.next() else { throw CancellationError() }
                group.cancelAll()
                return first
            }
            sessionUser = user
            router.isAuthenticated = true
            router.phase = .auth
        } catch InkAPIError.unauthorized {
            KeychainTokenStore.clear()
        } catch {
            // Ağ yavaşsa karşılama ekranı açık kalır; oturum anahtarı durur.
        }
    }

    private func handleSessionExpired() {
        guard router.isAuthenticated else { return }
        sessionUser = nil
        router.isAuthenticated = false
        router.showAuth()
    }

    func updateSessionUser(_ user: User) {
        sessionUser = user
    }

    func completeLogin(user: User) {
        sessionUser = user
        router.isAuthenticated = true
    }

    func completeLogout() async {
        await authService.logout()
        sessionUser = nil
        router.isAuthenticated = false
        router.showWelcome()
    }

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authService: authService, router: router, container: self)
    }
}
