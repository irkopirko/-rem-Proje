import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func register(name: String, email: String, password: String) async throws -> User
    func forgotPassword(email: String) async throws
    func logout() async
    var currentUser: User? { get }
}
