import Foundation
import Supabase

/// Type alias to disambiguate Supabase Auth's User from the app's User model.
private typealias AuthUser = Auth.User

final class SupabaseAuthService: AuthServiceProtocol {
    private let client = SupabaseManager.client
    private(set) var currentUser: User?

    // MARK: - Login

    func login(email: String, password: String) async throws -> User {
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            let user = try await fetchProfile(
                authId: session.user.id.uuidString,
                email: session.user.email ?? email
            )
            currentUser = user
            return user
        } catch {
            throw mapAuthError(error)
        }
    }

    // MARK: - Register

    func register(name: String, email: String, password: String) async throws -> User {
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )

            // AuthResponse.user is always non-nil
            let authUser = response.user

            // Insert a profile row in the public "profiles" table
            let profile = ProfileRow(
                id: authUser.id.uuidString,
                name: name,
                email: email,
                role: "student",
                avatar_url: nil
            )
            try await client.from("profiles")
                .insert(profile)
                .execute()

            let user = User(
                id: authUser.id.uuidString,
                name: name,
                email: email,
                role: .student,
                avatarURL: nil
            )
            currentUser = user
            return user
        } catch let err as AuthError {
            throw err
        } catch {
            throw mapAuthError(error)
        }
    }

    // MARK: - Forgot Password

    func forgotPassword(email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            throw mapAuthError(error)
        }
    }

    // MARK: - Logout

    func logout() async {
        try? await client.auth.signOut()
        currentUser = nil
    }

    // MARK: - Restore Session

    /// Call on app launch to restore an existing session.
    func restoreSession() async {
        // `session` throws if there is no valid session stored
        guard let session = try? await client.auth.session else { return }
        let email = session.user.email ?? ""
        if let user = try? await fetchProfile(authId: session.user.id.uuidString, email: email) {
            currentUser = user
        }
    }

    // MARK: - Helpers

    private func fetchProfile(authId: String, email: String) async throws -> User {
        let rows: [ProfileRow] = try await client.from("profiles")
            .select()
            .eq("id", value: authId)
            .execute()
            .value

        guard let row = rows.first else {
            // Profile row missing – return a minimal user
            return User(id: authId, name: email, email: email, role: .student, avatarURL: nil)
        }

        return User(
            id: row.id,
            name: row.name,
            email: row.email,
            role: User.Role(rawValue: row.role) ?? .student,
            avatarURL: row.avatar_url.flatMap(URL.init(string:))
        )
    }

    private func mapAuthError(_ error: Error) -> AuthError {
        let message = error.localizedDescription.lowercased()
        if message.contains("invalid login") || message.contains("invalid credentials") {
            return .invalidCredentials
        } else if message.contains("already registered") || message.contains("already been registered") {
            return .emailAlreadyInUse
        } else if message.contains("not found") || message.contains("no user") {
            return .userNotFound
        } else if message.contains("password") {
            return .weakPassword
        }
        return .networkError
    }
}

// MARK: - DB Row DTO

private struct ProfileRow: Codable {
    let id: String
    let name: String
    let email: String
    let role: String
    let avatar_url: String?
}