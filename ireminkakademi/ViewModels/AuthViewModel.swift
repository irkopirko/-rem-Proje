import Foundation

@Observable
final class AuthViewModel {
    let authService: AuthServiceProtocol
    let router: AppRouter
    let container: DIContainer

    /// E-posta adresi veya kullanıcı adı.
    var identifier = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    init(authService: AuthServiceProtocol, router: AppRouter, container: DIContainer) {
        self.authService = authService
        self.router = router
        self.container = container
    }

    func login() async {
        errorMessage = nil
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty else {
            errorMessage = "Kullanıcı adını veya e-mail adresini ve şifreni gir."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await authService.login(identifier: trimmed, password: password)
            container.completeLogin(user: user)
        } catch InkAPIError.unauthorized {
            errorMessage = LocalAuthError.invalidCredentials.errorDescription
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}
