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
            MainActor.assumeIsolated { self?.handleSessionExpired() }
        }
    }

    func bootstrapSession() async {
        guard !APIConfiguration.usesMockBackend,
              KeychainTokenStore.accessToken() != nil,
              let live = authService as? InkAuthService else { return }
        do {
            let user = try await live.fetchMe()
            sessionUser = user
            router.isAuthenticated = true
            router.phase = .auth
        } catch InkAPIError.unauthorized {
            KeychainTokenStore.clear()
        } catch {
            // Ağ hatasında oturum korunur; kullanıcı bir sonraki açılışta devam eder.
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
