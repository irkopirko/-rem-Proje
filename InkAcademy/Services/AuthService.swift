import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func register(name: String, email: String, password: String) async throws -> User
    func forgotPassword(email: String) async throws
    func changePassword(newPassword: String) async throws
    /// Uygulama tarafında hesap kapatma (Supabase profil işaretleme + oturum kapatma).
    func requestAccountDeletion() async throws
    func logout() async
    var currentUser: User? { get }
}
