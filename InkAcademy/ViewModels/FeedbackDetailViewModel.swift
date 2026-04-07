import Foundation

@Observable
final class FeedbackDetailViewModel {

    // MARK: - Data

    let assignment: Assignment
    let feedback: Feedback
    let assignmentService: AssignmentServiceProtocol

    // MARK: - Init

    init(
        assignment: Assignment,
        feedback: Feedback,
        assignmentService: AssignmentServiceProtocol
    ) {
        self.assignment = assignment
        self.feedback = feedback
        self.assignmentService = assignmentService
    }

    // MARK: - Computed — Display

    var assignmentTitle: String { assignment.title }

    var submissionDateFormatted: String? {
        assignment.submissionDate?.formatted_ddMMyyyy
    }

    var feedbackDateFormatted: String {
        feedback.date.formatted_ddMMyyyy
    }

    var instructorName: String { feedback.instructorName }

    var instructorInitials: String {
        feedback.instructorInitials
    }

    var comment: String { feedback.comment }

    var rating: Int { feedback.rating }
    var ratingMax: Int { 10 }

    var ratingProgress: Double {
        guard ratingMax > 0 else { return 0 }
        return Double(rating) / Double(ratingMax)
    }

    var hasSubmittedFile: Bool {
        assignment.fileURL != nil
    }

    var isRevisionRequested: Bool {
        assignment.status == .revisionRequested
    }

    var isApproved: Bool {
        assignment.status == .reviewed
    }

    var statusLabel: String {
        switch assignment.status {
        case .pending:            return "Bekliyor"
        case .submitted:          return "Gönderildi"
        case .reviewed:           return "Onaylandı"
        case .revisionRequested:  return "Revizyon İstendi"
        }
    }
}
