import Foundation

struct Feedback: Codable, Identifiable, Hashable {
    let id: String
    var assignmentId: String
    var instructorId: String
    var instructorName: String
    var comment: String
    var rating: Int
    var date: Date

    var instructorInitials: String {
        let parts = instructorName
            .replacingOccurrences(of: "Eğitmen ", with: "")
            .split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}
