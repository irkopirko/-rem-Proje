import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var email: String
    var role: Role
    var avatarURL: URL?

    enum Role: String, Codable, Hashable {
        case student
        case instructor
    }
}
