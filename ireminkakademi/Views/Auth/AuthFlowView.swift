import SwiftUI

struct AuthFlowView: View {
    let container: DIContainer
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(viewModel: container.makeAuthViewModel(), path: $path)
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .login:
                        LoginView(viewModel: container.makeAuthViewModel(), path: $path)
                    case .register:
                        RegisterView(authService: container.authService, path: $path, container: container)
                    case .problem:
                        ProblemSupportView(path: $path)
                    case .forgotPassword:
                        ForgotPasswordView(authService: container.authService, path: $path)
                    case .otp(let email):
                        OTPVerifyView(authService: container.authService, email: email, container: container)
                    case .contact:
                        ContactSupportView()
                    }
                }
        }
    }
}
