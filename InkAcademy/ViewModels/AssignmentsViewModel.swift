import Foundation

@Observable
final class AssignmentsViewModel {
    var assignments: [Assignment] = []
    var isLoading = false
    var errorMessage: String?

    let assignmentService: AssignmentServiceProtocol

    init(assignmentService: AssignmentServiceProtocol) {
        self.assignmentService = assignmentService
    }

    var pendingAssignments: [Assignment] {
        assignments.filter { $0.status == .pending }
    }

    var submittedAssignments: [Assignment] {
        assignments.filter { $0.status == .submitted }
    }

    var reviewedAssignments: [Assignment] {
        assignments.filter { $0.status == .reviewed }
    }

    var revisionRequestedAssignments: [Assignment] {
        assignments.filter { $0.status == .revisionRequested }
    }

    var nextDueAssignment: Assignment? {
        assignments
            .filter { $0.status == .pending }
            .sorted { $0.dueDate < $1.dueDate }
            .first
    }

    func loadAssignments() async {
        isLoading = true
        do {
            assignments = try await assignmentService.fetchAssignments()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func uploadAssignment(id: String, fileURL: URL) async {
        isLoading = true
        do {
            let updated = try await assignmentService.uploadAssignment(id: id, fileURL: fileURL)
            if let index = assignments.firstIndex(where: { $0.id == id }) {
                assignments[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
