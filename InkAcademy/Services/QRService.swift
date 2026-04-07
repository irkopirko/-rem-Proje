import Foundation

protocol QRServiceProtocol {
    func unlockModule(qrPayload: String) async throws -> TrainingModule
    func resolveLesson(qrPayload: String) async throws -> QRLessonResolution
}
