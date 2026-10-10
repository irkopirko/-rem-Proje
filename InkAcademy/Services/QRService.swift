import Foundation

protocol QRServiceProtocol {
    func unlockModule(qrPayload: String) async throws -> CourseModule
    func resolveLesson(qrPayload: String) async throws -> QRLessonResolution
    func resolveContent(qrPayload: String) async throws -> QRResolution
}
