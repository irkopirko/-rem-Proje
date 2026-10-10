import Foundation

final class MockModuleService: ModuleServiceProtocol {
    private var modules: [CourseModule] = []

    func fetchModules() async throws -> [CourseModule] {
        try await Task.sleep(for: .milliseconds(800))
        var data = try MockDataLoader.load("modules", as: [CourseModule].self)
        let bundledVideoURL = Bundle.main.url(forResource: "demo", withExtension: "mp4")

        if let bundledVideoURL {
            for moduleIndex in data.indices {
                for lessonIndex in data[moduleIndex].lessons.indices where data[moduleIndex].lessons[lessonIndex].videoURL == nil {
                    data[moduleIndex].lessons[lessonIndex].videoURL = bundledVideoURL
                }
            }
        }

        modules = data
        return data
    }

    func fetchLessons(moduleId: String) async throws -> [Lesson] {
        try await Task.sleep(for: .milliseconds(500))
        return modules.first(where: { $0.id == moduleId })?.lessons ?? []
    }

    func fetchQuiz(lessonId: String) async throws -> Quiz? {
        try await Task.sleep(for: .milliseconds(500))
        let quizzes = try MockDataLoader.load("quizzes", as: [Quiz].self)
        return quizzes.first(where: { $0.lessonId == lessonId })
    }

    func submitQuiz(quizId: String, answers: [Int]) async throws -> Int {
        try await Task.sleep(for: .milliseconds(600))
        let quizzes = try MockDataLoader.load("quizzes", as: [Quiz].self)
        guard let quiz = quizzes.first(where: { $0.id == quizId }) else { return 0 }

        var correct = 0
        for (index, answer) in answers.enumerated() {
            if index < quiz.questions.count && quiz.questions[index].correctOptionIndex == answer {
                correct += 1
            }
        }
        return correct
    }

    func markLessonComplete(lessonId: String) async throws {
        try await Task.sleep(for: .milliseconds(300))
        for i in modules.indices {
            if let j = modules[i].lessons.firstIndex(where: { $0.id == lessonId }) {
                modules[i].lessons[j].isCompleted = true
            }
        }
    }
}

// MARK: - Mock Data Loader

enum MockDataLoader {
    static func load<T: Decodable>(_ filename: String, as type: T.Type) throws -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw MockError.fileNotFound(filename)
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}

enum MockError: LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name): return "Mock data file '\(name).json' not found."
        }
    }
}
