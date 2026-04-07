import Foundation

@Observable
final class AuthViewModel {

    // MARK: - Shared fields

    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    // MARK: - Register-only fields

    var name = ""
    var confirmPassword = ""

    // MARK: - Forgot-password state

    var resetEmailSent = false

    // MARK: - Field-level validation errors (shown after first submit attempt)

    var emailError: String?
    var passwordError: String?
    var nameError: String?
    var confirmPasswordError: String?

    // MARK: - Dependencies

    let authService: AuthServiceProtocol
    private let router: AppRouter

    init(authService: AuthServiceProtocol, router: AppRouter) {
        self.authService = authService
        self.router = router
    }

    // MARK: - Login

    func login() async {
        guard validateLogin() else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.login(email: email.trimmed, password: password)
            router.isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Register

    func register() async {
        guard validateRegister() else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.register(
                name: name.trimmed,
                email: email.trimmed,
                password: password
            )
            router.isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Forgot Password

    func forgotPassword() async {
        guard validateForgotPassword() else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.forgotPassword(email: email.trimmed)
            resetEmailSent = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Clear state (call when switching between auth screens)

    func clearFields() {
        name = ""
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
        emailError = nil
        passwordError = nil
        nameError = nil
        confirmPasswordError = nil
        resetEmailSent = false
    }

    // MARK: - Validation

    private func validateLogin() -> Bool {
        var valid = true
        emailError = nil
        passwordError = nil
        errorMessage = nil

        if email.trimmed.isEmpty {
            emailError = "E-posta adresi gerekli."
            valid = false
        } else if !email.trimmed.isValidEmail {
            emailError = "Geçerli bir e-posta girin."
            valid = false
        }

        if password.isEmpty {
            passwordError = "Şifre gerekli."
            valid = false
        } else if password.count < 6 {
            passwordError = "Şifre en az 6 karakter olmalı."
            valid = false
        }

        return valid
    }

    private func validateRegister() -> Bool {
        var valid = true
        nameError = nil
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        errorMessage = nil

        if name.trimmed.isEmpty {
            nameError = "Ad Soyad gerekli."
            valid = false
        }

        if email.trimmed.isEmpty {
            emailError = "E-posta adresi gerekli."
            valid = false
        } else if !email.trimmed.isValidEmail {
            emailError = "Geçerli bir e-posta girin."
            valid = false
        }

        if password.isEmpty {
            passwordError = "Şifre gerekli."
            valid = false
        } else if password.count < 6 {
            passwordError = "Şifre en az 6 karakter olmalı."
            valid = false
        }

        if confirmPassword.isEmpty {
            confirmPasswordError = "Şifre tekrarı gerekli."
            valid = false
        } else if confirmPassword != password {
            confirmPasswordError = "Şifreler eşleşmiyor."
            valid = false
        }

        return valid
    }

    private func validateForgotPassword() -> Bool {
        emailError = nil
        errorMessage = nil

        if email.trimmed.isEmpty {
            emailError = "E-posta adresi gerekli."
            return false
        }
        if !email.trimmed.isValidEmail {
            emailError = "Geçerli bir e-posta girin."
            return false
        }
        return true
    }
}

// MARK: - String helpers

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }
}
