import Foundation

protocol AuthServiceProtocol {
    /// `identifier` e-posta adresi veya kullanıcı adı olabilir.
    func login(identifier: String, password: String) async throws -> User
    func isUsernameAvailable(_ username: String) async throws -> Bool
    func registerStart(firstName: String, lastName: String, username: String, email: String, password: String, birthDate: String?) async throws
    func registerVerify(email: String, code: String) async throws -> User
    func forgotPassword(email: String) async throws
    func resetPassword(email: String, code: String, newPassword: String) async throws
    func changePassword(currentPassword: String, newPassword: String) async throws
    func fetchMe() async throws -> User
    func deleteAccount(password: String) async throws
    /// Yeni fotoğraf yüklenir; sunucu eskisini anında siler.
    func updateProfilePhoto(jpegData: Data) async throws -> User
    func removeProfilePhoto() async throws -> User
    func logout() async
    var currentUser: User? { get }
}

extension AuthServiceProtocol {
    func updateProfilePhoto(jpegData: Data) async throws -> User {
        throw InkAPIError.server("Profil fotoğrafı için sunucu bağlantısı gerekiyor.")
    }

    func removeProfilePhoto() async throws -> User {
        throw InkAPIError.server("Profil fotoğrafı için sunucu bağlantısı gerekiyor.")
    }
}

final class InkAuthService: AuthServiceProtocol {
    private let api = InkAPIClient.shared
    private(set) var currentUser: User?

    func login(identifier: String, password: String) async throws -> User {
        struct Body: Encodable { let identifier: String; let password: String }
        let normalized = identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let resp: AuthTokens = try await api.request("/auth/login", method: "POST", body: Body(identifier: normalized, password: password))
        KeychainTokenStore.save(access: resp.accessToken, refresh: resp.refreshToken ?? "")
        currentUser = resp.user
        return resp.user
    }

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        struct Resp: Decodable { let available: Bool }
        var components = URLComponents()
        components.path = "/auth/username-available"
        components.queryItems = [URLQueryItem(name: "username", value: UsernameRules.normalize(username))]
        let resp: Resp = try await api.request(components.string ?? "/auth/username-available")
        return resp.available
    }

    func registerStart(firstName: String, lastName: String, username: String, email: String, password: String, birthDate: String?) async throws {
        struct Body: Encodable {
            let firstName: String
            let lastName: String
            let username: String
            let email: String
            let password: String
            let birthDate: String?
        }
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await api.request(
            "/auth/register/start",
            method: "POST",
            body: Body(
                firstName: firstName,
                lastName: lastName,
                username: UsernameRules.normalize(username),
                email: email.lowercased(),
                password: password,
                birthDate: birthDate
            )
        )
    }

    func registerVerify(email: String, code: String) async throws -> User {
        struct Body: Encodable { let email: String; let code: String }
        let resp: AuthTokens = try await api.request("/auth/register/verify", method: "POST", body: Body(email: email.lowercased(), code: code))
        KeychainTokenStore.save(access: resp.accessToken, refresh: resp.refreshToken ?? "")
        currentUser = resp.user
        return resp.user
    }

    func forgotPassword(email: String) async throws {
        struct Body: Encodable { let email: String }
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await api.request("/auth/password/forgot", method: "POST", body: Body(email: email.lowercased()))
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        struct Body: Encodable { let email: String; let code: String; let newPassword: String }
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await api.request(
            "/auth/password/reset",
            method: "POST",
            body: Body(email: email.lowercased(), code: code, newPassword: newPassword)
        )
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        struct Body: Encodable { let currentPassword: String; let newPassword: String }
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await api.request(
            "/auth/password/change",
            method: "POST",
            body: Body(currentPassword: currentPassword, newPassword: newPassword),
            authorized: true
        )
    }

    func fetchMe() async throws -> User {
        struct Resp: Decodable { let user: User }
        let resp: Resp = try await api.request("/auth/me", authorized: true)
        currentUser = resp.user
        return resp.user
    }

    func deleteAccount(password: String) async throws {
        struct Body: Encodable { let password: String }
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await api.request("/auth/me", method: "DELETE", body: Body(password: password), authorized: true)
        KeychainTokenStore.clear()
        currentUser = nil
    }

    private struct UserResp: Decodable { let user: User }

    func updateProfilePhoto(jpegData: Data) async throws -> User {
        let resp: UserResp = try await api.upload("/auth/me/photo", method: "PUT", data: jpegData, contentType: "image/jpeg")
        currentUser = resp.user
        return resp.user
    }

    func removeProfilePhoto() async throws -> User {
        let resp: UserResp = try await api.request("/auth/me/photo", method: "DELETE", authorized: true)
        currentUser = resp.user
        return resp.user
    }

    func logout() async {
        if let refresh = KeychainTokenStore.refreshToken(), !refresh.isEmpty {
            struct Body: Encodable { let refreshToken: String }
            struct OK: Decodable { let ok: Bool }
            let _: OK? = try? await api.request("/auth/logout", method: "POST", body: Body(refreshToken: refresh), authorized: true)
        }
        KeychainTokenStore.clear()
        currentUser = nil
    }
}

final class MockAuthService: AuthServiceProtocol {
    private(set) var currentUser: User? = User(
        id: "mock",
        userNo: 1,
        username: "demo.ogrenci",
        birthDate: "2000-01-01",
        email: "ogrenci@example.com",
        firstName: "Demo",
        lastName: "Öğrenci",
        role: .student,
        membershipStatus: .trial,
        profilePhotoUrl: nil
    )

    func login(identifier: String, password: String) async throws -> User { currentUser! }
    func isUsernameAvailable(_ username: String) async throws -> Bool { true }
    func registerStart(firstName: String, lastName: String, username: String, email: String, password: String, birthDate: String?) async throws {}
    func registerVerify(email: String, code: String) async throws -> User { currentUser! }
    func forgotPassword(email: String) async throws {}
    func resetPassword(email: String, code: String, newPassword: String) async throws {}
    func changePassword(currentPassword: String, newPassword: String) async throws {}
    func fetchMe() async throws -> User { currentUser! }
    func deleteAccount(password: String) async throws { currentUser = nil }
    func logout() async { currentUser = nil }
}
