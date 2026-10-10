import Foundation

struct Certificate: Identifiable, Hashable, Codable {
    let id: String
    var title: String
    var issuedDate: Date?
    var level: String
    var certificateCode: String
    var isUnlocked: Bool
}
