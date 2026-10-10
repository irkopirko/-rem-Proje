import Foundation

enum AppPhase: Equatable {
    case welcome
    case auth
}

@Observable
final class AppRouter {
    var phase: AppPhase = .welcome
    var isAuthenticated = false
    var authPath: AuthRoute?

    func showWelcome() { phase = .welcome }
    func showAuth() { phase = .auth }
}

enum AuthRoute: Hashable {
    case login
    case register
    case problem
    case forgotPassword
    case otp(email: String)
    case contact
}
