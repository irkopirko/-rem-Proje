import Foundation

struct Assignment: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var description: String
    var dueDate: Date
    var submissionDate: Date?
    var fileURL: URL?
    var status: Status
    var feedback: Feedback?

    enum Status: String, Codable, Hashable {
        case pending
        case submitted
        case reviewed
        case revisionRequested
    }
}
