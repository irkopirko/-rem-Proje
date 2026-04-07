import Foundation

protocol AssignmentServiceProtocol {
    func fetchAssignments() async throws -> [Assignment]
    func uploadAssignment(id: String, fileURL: URL) async throws -> Assignment
    func fetchFeedback(assignmentId: String) async throws -> Feedback?
}
