import Foundation

final class MockQRService: QRServiceProtocol {
    private let accessDeniedLessonIds: Set<String> = ["lesson-2-2", "lesson-3-1"]

    func unlockModule(qrPayload: String) async throws -> TrainingModule {
        try await Task.sleep(for: .seconds(1))

        // Simulate unlocking a module by QR code payload
        return TrainingModule(
            id: qrPayload,
            title: "Kilidi Açılan Modül",
            description: "Bu modül QR kod ile açılmıştır.",
            imageURL: nil,
            lessons: [],
            isLocked: false
        )
    }

    func resolveLesson(qrPayload: String) async throws -> QRLessonResolution {
        try await Task.sleep(for: .milliseconds(600))

        let trimmed = qrPayload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let lessonId = Self.lessonId(from: trimmed) else {
            return .invalid
        }

        if accessDeniedLessonIds.contains(lessonId) || trimmed.hasPrefix("INKA-PRO:") {
            return .accessDenied
        }

        let modules = try MockDataLoader.load("modules", as: [TrainingModule].self)
        let lessons = modules.flatMap { $0.lessons }
        if let lesson = lessons.first(where: { $0.id == lessonId }) {
            return .lesson(lesson)
        }

        return .invalid
    }

    private static func lessonId(from payload: String) -> String? {
        if payload.hasPrefix("INKA:") {
            return String(payload.dropFirst("INKA:".count))
        }
        if payload.hasPrefix("INKA-") {
            return String(payload.dropFirst("INKA-".count))
        }
        if payload.hasPrefix("lesson-") {
            return payload
        }
        return nil
    }
}
