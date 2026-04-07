import Foundation

final class MockAssignmentService: AssignmentServiceProtocol {
    private var assignments: [Assignment] = []

    func fetchAssignments() async throws -> [Assignment] {
        try await Task.sleep(for: .milliseconds(800))
        let data = try MockDataLoader.load("assignments", as: [Assignment].self)
        assignments = data
        return data
    }

    func uploadAssignment(id: String, fileURL: URL) async throws -> Assignment {
        try await Task.sleep(for: .seconds(1))
        guard var assignment = assignments.first(where: { $0.id == id }) else {
            throw AssignmentError.notFound
        }
        assignment.status = .submitted
        assignment.fileURL = fileURL
        return assignment
    }

    func fetchFeedback(assignmentId: String) async throws -> Feedback? {
        try await Task.sleep(for: .milliseconds(500))
        let assignment = assignments.first(where: { $0.id == assignmentId })
        return assignment?.feedback
    }
}

enum AssignmentError: LocalizedError {
    case notFound
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .notFound: return "Ödev bulunamadı."
        case .uploadFailed: return "Yükleme başarısız oldu."
        }
    }
}
