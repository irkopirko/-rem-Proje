import Foundation
import AVFoundation

@Observable
final class LessonDetailViewModel {

    // MARK: - Lesson state

    var lesson: Lesson
    var isCompleted: Bool
    var isLoading = false
    var errorMessage: String?

    // MARK: - Related content

    var quiz: Quiz?
    var relatedAssignment: Assignment?

    // MARK: - Video

    private(set) var player: AVPlayer?

    // MARK: - Notes (simulated — would come from API)

    var notes: String? {
        lesson.description.isEmpty ? nil : lesson.description
    }

    // MARK: - Dependencies

    let moduleService: ModuleServiceProtocol
    let assignmentService: AssignmentServiceProtocol

    // MARK: - Init

    init(
        lesson: Lesson,
        moduleService: ModuleServiceProtocol,
        assignmentService: AssignmentServiceProtocol
    ) {
        self.lesson = lesson
        self.isCompleted = lesson.isCompleted
        self.moduleService = moduleService
        self.assignmentService = assignmentService

        if let url = lesson.videoURL {
            self.player = AVPlayer(url: url)
        }
    }

    // MARK: - Load related data

    func loadRelatedContent() async {
        async let quizResult: Quiz? = loadQuiz()
        async let assignmentResult: Assignment? = loadAssignment()

        quiz = await quizResult
        relatedAssignment = await assignmentResult
    }

    private func loadQuiz() async -> Quiz? {
        do {
            return try await moduleService.fetchQuiz(lessonId: lesson.id)
        } catch {
            return nil
        }
    }

    private func loadAssignment() async -> Assignment? {
        do {
            let all = try await assignmentService.fetchAssignments()
            // Match by convention: assignment title contains a keyword from lesson
            // In production this would be a proper lessonId FK
            return all.first
        } catch {
            return nil
        }
    }

    // MARK: - Mark complete

    func markComplete() async {
        isLoading = true
        errorMessage = nil

        do {
            try await moduleService.markLessonComplete(lessonId: lesson.id)
            isCompleted = true
            lesson.isCompleted = true
        } catch {
            errorMessage = "Tamamlama başarısız oldu."
        }

        isLoading = false
    }

    // MARK: - Cleanup

    func pauseVideo() {
        player?.pause()
    }
}
