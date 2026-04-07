import Foundation

@Observable
final class QuizViewModel {

    // MARK: - Data

    let quiz: Quiz
    private let moduleService: ModuleServiceProtocol

    // MARK: - State

    var currentQuestionIndex = 0
    var selectedAnswers: [Int?]
    var isSubmitted = false
    var score = 0
    var isLoading = false

    // MARK: - Init

    init(quiz: Quiz, moduleService: ModuleServiceProtocol) {
        self.quiz = quiz
        self.moduleService = moduleService
        self.selectedAnswers = Array(repeating: nil, count: quiz.questions.count)
    }

    // MARK: - Computed — Current question

    var totalQuestions: Int { quiz.questions.count }

    var currentQuestion: Question? {
        guard quiz.questions.indices.contains(currentQuestionIndex) else { return nil }
        return quiz.questions[currentQuestionIndex]
    }

    var isFirstQuestion: Bool { currentQuestionIndex == 0 }
    var isLastQuestion: Bool { currentQuestionIndex == totalQuestions - 1 }

    var currentSelectedAnswer: Int? {
        guard selectedAnswers.indices.contains(currentQuestionIndex) else { return nil }
        return selectedAnswers[currentQuestionIndex]
    }

    var hasAnsweredCurrent: Bool {
        currentSelectedAnswer != nil
    }

    // MARK: - Computed — Progress

    var progress: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(totalQuestions)
    }

    var progressText: String {
        "\(currentQuestionIndex + 1) / \(totalQuestions)"
    }

    var answeredCount: Int {
        selectedAnswers.compactMap { $0 }.count
    }

    var canSubmit: Bool {
        selectedAnswers.allSatisfy { $0 != nil }
    }

    // MARK: - Computed — Results

    var passed: Bool {
        score >= quiz.passingScore
    }

    var scorePercent: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int(Double(score) / Double(totalQuestions) * 100)
    }

    /// Per-question review data after submission.
    var reviewItems: [ReviewItem] {
        quiz.questions.enumerated().map { index, question in
            let selected = selectedAnswers[index]
            return ReviewItem(
                question: question,
                selectedIndex: selected,
                isCorrect: selected == question.correctOptionIndex
            )
        }
    }

    // MARK: - Actions — Navigation

    func selectAnswer(_ index: Int) {
        guard !isSubmitted else { return }
        selectedAnswers[currentQuestionIndex] = index
    }

    func nextQuestion() {
        guard !isLastQuestion else { return }
        currentQuestionIndex += 1
    }

    func previousQuestion() {
        guard !isFirstQuestion else { return }
        currentQuestionIndex -= 1
    }

    func goToQuestion(_ index: Int) {
        guard index >= 0, index < totalQuestions else { return }
        currentQuestionIndex = index
    }

    // MARK: - Actions — Submit

    func submit() async {
        guard canSubmit else { return }
        isLoading = true

        let answers = selectedAnswers.compactMap { $0 }
        do {
            score = try await moduleService.submitQuiz(quizId: quiz.id, answers: answers)
            isSubmitted = true
        } catch {
            // Fail silently for now — would show error in production
        }

        isLoading = false
    }

    // MARK: - Actions — Retry

    func retry() {
        currentQuestionIndex = 0
        selectedAnswers = Array(repeating: nil, count: totalQuestions)
        isSubmitted = false
        score = 0
    }
}

// MARK: - Review Item

struct ReviewItem: Identifiable {
    let question: Question
    let selectedIndex: Int?
    let isCorrect: Bool

    var id: String { question.id }

    var selectedText: String? {
        guard let idx = selectedIndex, idx < question.options.count else { return nil }
        return question.options[idx]
    }

    var correctText: String {
        question.options[question.correctOptionIndex]
    }
}
