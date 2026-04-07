import Foundation
import Supabase

final class SupabaseModuleService: ModuleServiceProtocol {
    private let client = SupabaseManager.client

    // MARK: - Fetch Modules

    func fetchModules() async throws -> [TrainingModule] {
        // Fetch modules with nested lessons in a single query
        let rows: [ModuleRow] = try await client.from("modules")
            .select("*, lessons(*)")
            .order("order", ascending: true)
            .execute()
            .value

        return rows.map { $0.toDomain() }
    }

    // MARK: - Fetch Lessons

    func fetchLessons(moduleId: String) async throws -> [Lesson] {
        let rows: [LessonRow] = try await client.from("lessons")
            .select()
            .eq("module_id", value: moduleId)
            .order("order", ascending: true)
            .execute()
            .value

        return rows.map { $0.toDomain() }
    }

    // MARK: - Fetch Quiz

    func fetchQuiz(lessonId: String) async throws -> Quiz? {
        let rows: [QuizRow] = try await client.from("quizzes")
            .select("*, questions(*)")
            .eq("lesson_id", value: lessonId)
            .limit(1)
            .execute()
            .value

        return rows.first?.toDomain()
    }

    // MARK: - Submit Quiz

    func submitQuiz(quizId: String, answers: [Int]) async throws -> Int {
        // Fetch correct answers from the DB
        let rows: [QuizRow] = try await client.from("quizzes")
            .select("*, questions(*)")
            .eq("id", value: quizId)
            .limit(1)
            .execute()
            .value

        guard let quiz = rows.first else { return 0 }

        var correct = 0
        let sorted = quiz.questions.sorted { $0.order < $1.order }
        for (index, answer) in answers.enumerated() where index < sorted.count {
            if sorted[index].correct_option_index == answer {
                correct += 1
            }
        }

        // Optionally: persist the submission
        let userId = try? await client.auth.session.user.id.uuidString
        if let userId {
            try? await client.from("quiz_submissions")
                .insert([
                    "quiz_id": quizId,
                    "user_id": userId,
                    "score": "\(correct)",
                    "total": "\(sorted.count)"
                ])
                .execute()
        }

        return correct
    }

    // MARK: - Mark Lesson Complete

    func markLessonComplete(lessonId: String) async throws {
        guard let userId = try? await client.auth.session.user.id.uuidString else { return }

        try await client.from("lesson_completions")
            .upsert([
                "user_id": userId,
                "lesson_id": lessonId
            ])
            .execute()
    }
}

// MARK: - DB Row DTOs

private struct ModuleRow: Codable {
    let id: String
    let title: String
    let description: String
    let image_url: String?
    let is_locked: Bool
    let order: Int
    let lessons: [LessonRow]

    func toDomain() -> TrainingModule {
        TrainingModule(
            id: id,
            title: title,
            description: description,
            imageURL: image_url.flatMap(URL.init(string:)),
            lessons: lessons
                .sorted { $0.order < $1.order }
                .map { $0.toDomain() },
            isLocked: is_locked
        )
    }
}

private struct LessonRow: Codable {
    let id: String
    let module_id: String
    let title: String
    let video_url: String?
    let duration: Double
    let order: Int
    let is_completed: Bool?
    let description: String

    func toDomain() -> Lesson {
        Lesson(
            id: id,
            title: title,
            videoURL: video_url.flatMap(URL.init(string:)),
            duration: duration,
            order: order,
            isCompleted: is_completed ?? false,
            description: description
        )
    }
}

private struct QuizRow: Codable {
    let id: String
    let lesson_id: String
    let passing_score: Int
    let questions: [QuestionRow]

    func toDomain() -> Quiz {
        Quiz(
            id: id,
            lessonId: lesson_id,
            questions: questions
                .sorted { $0.order < $1.order }
                .map { $0.toDomain() },
            passingScore: passing_score
        )
    }
}

private struct QuestionRow: Codable {
    let id: String
    let text: String
    let options: [String]
    let correct_option_index: Int
    let type: String
    let order: Int

    func toDomain() -> Question {
        Question(
            id: id,
            text: text,
            options: options,
            correctOptionIndex: correct_option_index,
            type: QuestionType(rawValue: type) ?? .multipleChoice
        )
    }
}
