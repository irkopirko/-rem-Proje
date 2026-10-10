import Foundation

protocol ModuleServiceProtocol {
    func fetchModules() async throws -> [CourseModule]
    func fetchLessons(moduleId: String) async throws -> [Lesson]
    func fetchQuiz(lessonId: String) async throws -> Quiz?
    func submitQuiz(quizId: String, answers: [Int]) async throws -> Int
    func markLessonComplete(lessonId: String) async throws
}
