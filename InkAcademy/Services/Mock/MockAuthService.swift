import Foundation

final class MockAuthService: AuthServiceProtocol {
    private struct Account {
        let password: String
        let user: User
    }

    private(set) var currentUser: User?

    private var accounts: [String: Account] = [
        "student@inkakademi.com": Account(
            password: "123456",
            user: User(
                id: "user-demo",
                name: "Ahmet Yılmaz",
                email: "student@inkakademi.com",
                role: .student,
                avatarURL: nil
            )
        ),
        "iremcelikk2@hotmail.com": Account(
            password: "123Remi*",
            user: User(
                id: "user-irem",
                name: "İrem Çelik",
                email: "iremcelikk2@hotmail.com",
                role: .student,
                avatarURL: nil
            )
        )
    ]

    func login(email: String, password: String) async throws -> User {
        try await Task.sleep(for: .seconds(1))

        let key = email.lowercased()
        guard let account = accounts[key], account.password == password else {
            throw AuthError.invalidCredentials
        }

        currentUser = account.user
        return account.user
    }

    func register(name: String, email: String, password: String) async throws -> User {
        try await Task.sleep(for: .seconds(1.2))

        let key = email.lowercased()
        guard accounts[key] == nil else {
            throw AuthError.emailAlreadyInUse
        }
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }

        let user = User(
            id: UUID().uuidString,
            name: name,
            email: email,
            role: .student,
            avatarURL: nil
        )
        accounts[key] = Account(password: password, user: user)
        currentUser = user
        return user
    }

    func forgotPassword(email: String) async throws {
        try await Task.sleep(for: .seconds(1))

        guard accounts[email.lowercased()] != nil else {
            throw AuthError.userNotFound
        }
    }

    func changePassword(newPassword: String) async throws {
        try await Task.sleep(for: .milliseconds(400))
        guard newPassword.count >= 6 else { throw AuthError.weakPassword }
        guard let user = currentUser,
              let key = accounts.first(where: { $0.value.user.id == user.id })?.key,
              let existing = accounts[key] else {
            throw AuthError.userNotFound
        }
        accounts[key] = Account(password: newPassword, user: existing.user)
    }

    func requestAccountDeletion() async throws {
        try await Task.sleep(for: .seconds(0.8))
        currentUser = nil
    }

    func logout() async {
        currentUser = nil
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case userNotFound
    case weakPassword
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Geçersiz e-posta veya şifre."
        case .emailAlreadyInUse:
            return "Bu e-posta adresi zaten kayıtlı."
        case .userNotFound:
            return "Bu e-posta ile kayıtlı bir hesap bulunamadı."
        case .weakPassword:
            return "Şifre en az 6 karakter olmalıdır."
        case .networkError:
            return "Bağlantı hatası. Lütfen tekrar deneyin."
        }
    }
}
