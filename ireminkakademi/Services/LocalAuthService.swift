import Foundation
import CryptoKit

enum LocalAuthError: LocalizedError {
    case emailTaken
    case usernameTaken
    case invalidCredentials
    case invalidCode
    case notLoggedIn

    var errorDescription: String? {
        switch self {
        case .emailTaken: return "Bu e-posta ile zaten bir hesap var."
        case .usernameTaken: return "Bu kullanıcı adı alınmış. Lütfen başka bir kullanıcı adı seç."
        case .invalidCredentials: return "Kullanıcı adı, e-mail veya şifre yanlış. Lütfen tekrar deneyiniz."
        case .invalidCode: return "Kod geçersiz veya süresi dolmuş."
        case .notLoggedIn: return "Oturum bulunamadı."
        }
    }
}

/// Sunucu henüz bağlanmadan (Debug) kayıt, onay kodu ve giriş akışını cihazda test etmek için.
final class LocalAuthService: AuthServiceProtocol {
    private struct StoredUser: Codable {
        var user: User
        var passwordHash: String
    }

    private struct PendingRegistration {
        let user: StoredUser
        let code: String
    }

    private let storageKey = "ireminkakademi.local_users.v1"
    private var pendingRegistrations: [String: PendingRegistration] = [:]
    private var resetCodes: [String: String] = [:]

    private(set) var currentUser: User?
    /// Geliştirme modunda onay kodu e-posta yerine ekranda gösterilir.
    private(set) var lastIssuedCode: String?

    func login(identifier: String, password: String) async throws -> User {
        let key = normalize(identifier)
        let users = loadUsers()
        let stored = key.contains("@") ? users[key] : users.values.first { $0.user.username == key }
        guard let stored, stored.passwordHash == hash(password) else {
            throw LocalAuthError.invalidCredentials
        }
        currentUser = stored.user
        return stored.user
    }

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let key = UsernameRules.normalize(username)
        guard !UsernameRules.reserved.contains(key) else { return false }
        let takenByUser = loadUsers().values.contains { $0.user.username == key }
        let takenByPending = pendingRegistrations.values.contains { $0.user.user.username == key }
        return !takenByUser && !takenByPending
    }

    func registerStart(firstName: String, lastName: String, username: String, email: String, password: String, birthDate: String?) async throws {
        let key = normalize(email)
        let users = loadUsers()
        guard users[key] == nil else { throw LocalAuthError.emailTaken }
        pendingRegistrations[key] = nil
        guard try await isUsernameAvailable(username) else { throw LocalAuthError.usernameTaken }

        let user = User(
            id: UUID().uuidString,
            userNo: users.count + 1,
            username: UsernameRules.normalize(username),
            birthDate: birthDate,
            email: key,
            firstName: firstName,
            lastName: lastName,
            role: .student,
            membershipStatus: .trial,
            profilePhotoUrl: nil
        )
        let code = randomCode()
        pendingRegistrations[key] = PendingRegistration(
            user: StoredUser(user: user, passwordHash: hash(password)),
            code: code
        )
        lastIssuedCode = code
    }

    func registerVerify(email: String, code: String) async throws -> User {
        let key = normalize(email)
        guard let pending = pendingRegistrations[key], pending.code == code else {
            throw LocalAuthError.invalidCode
        }
        var users = loadUsers()
        users[key] = pending.user
        saveUsers(users)
        pendingRegistrations[key] = nil
        lastIssuedCode = nil
        currentUser = pending.user.user
        return pending.user.user
    }

    func forgotPassword(email: String) async throws {
        let key = normalize(email)
        let code = randomCode()
        resetCodes[key] = code
        lastIssuedCode = code
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        let key = normalize(email)
        guard resetCodes[key] == code, var stored = loadUsers()[key] else { throw LocalAuthError.invalidCode }
        stored.passwordHash = hash(newPassword)
        var users = loadUsers()
        users[key] = stored
        saveUsers(users)
        resetCodes[key] = nil
        lastIssuedCode = nil
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let email = currentUser?.email, var stored = loadUsers()[email] else { throw LocalAuthError.notLoggedIn }
        guard stored.passwordHash == hash(currentPassword) else { throw LocalAuthError.invalidCredentials }
        stored.passwordHash = hash(newPassword)
        var users = loadUsers()
        users[email] = stored
        saveUsers(users)
    }

    func fetchMe() async throws -> User {
        guard let currentUser else { throw LocalAuthError.notLoggedIn }
        return currentUser
    }

    func deleteAccount(password: String) async throws {
        guard let email = currentUser?.email, let stored = loadUsers()[email] else { throw LocalAuthError.notLoggedIn }
        guard stored.passwordHash == hash(password) else { throw LocalAuthError.invalidCredentials }
        var users = loadUsers()
        users[email] = nil
        saveUsers(users)
        currentUser = nil
    }

    func logout() async {
        currentUser = nil
    }

    private func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func hash(_ password: String) -> String {
        SHA256.hash(data: Data(password.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func randomCode() -> String {
        String(Int.random(in: 100_000...999_999))
    }

    private func loadUsers() -> [String: StoredUser] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let users = try? JSONDecoder().decode([String: StoredUser].self, from: data) else { return [:] }
        return users
    }

    private func saveUsers(_ users: [String: StoredUser]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
