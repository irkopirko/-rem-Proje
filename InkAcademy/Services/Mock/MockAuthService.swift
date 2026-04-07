import Foundation

final class MockAuthService: AuthServiceProtocol {
    private(set) var currentUser: User?

    // Simulated registered accounts
    private var registeredEmails: Set<String> = ["student@inkakademi.com"]

    func login(email: String, password: String) async throws -> User {
        try await Task.sleep(for: .seconds(1))

        guard registeredEmails.contains(email.lowercased()) else {
            throw AuthError.invalidCredentials
        }
        guard password.count >= 6 else {
            throw AuthError.invalidCredentials
        }

        let user = User(
            id: "user-1",
            name: "Ahmet Yılmaz",
            email: email,
            role: .student,
            avatarURL: nil
        )
        currentUser = user
        return user
    }

    func register(name: String, email: String, password: String) async throws -> User {
        try await Task.sleep(for: .seconds(1.2))

        guard !registeredEmails.contains(email.lowercased()) else {
            throw AuthError.emailAlreadyInUse
        }

        registeredEmails.insert(email.lowercased())

        let user = User(
            id: UUID().uuidString,
            name: name,
            email: email,
            role: .student,
            avatarURL: nil
        )
        currentUser = user
        return user
    }

    func forgotPassword(email: String) async throws {
        try await Task.sleep(for: .seconds(1))

        guard registeredEmails.contains(email.lowercased()) else {
            throw AuthError.userNotFound
        }
        // Mock: pretend we sent a reset email
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
