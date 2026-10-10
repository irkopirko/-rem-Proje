import Foundation
import Supabase

final class SupabaseQRService: QRServiceProtocol {
    private let client = SupabaseManager.client

    // MARK: - Unlock Module

    func unlockModule(qrPayload: String) async throws -> CourseModule {
        // Look up the module linked to this QR code
        let rows: [QRCodeRow] = try await client.from("qr_codes")
            .select("module_id")
            .eq("payload", value: qrPayload)
            .limit(1)
            .execute()
            .value

        guard let moduleId = rows.first?.module_id else {
            throw QRError.invalidCode
        }

        // Mark it unlocked for the current user
        if let userId = try? await client.auth.session.user.id.uuidString {
            try? await client.from("user_module_unlocks")
                .upsert([
                    "user_id": userId,
                    "module_id": moduleId
                ])
                .execute()
        }

        // Fetch and return the module
        let moduleRows: [ModuleQRRow] = try await client.from("modules")
            .select("*, lessons(*)")
            .eq("id", value: moduleId)
            .limit(1)
            .execute()
            .value

        guard let row = moduleRows.first else { throw QRError.moduleNotFound }
        return row.toDomain()
    }

    // MARK: - Resolve Lesson

    func resolveLesson(qrPayload: String) async throws -> QRLessonResolution {
        let trimmed = qrPayload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let lessonId = Self.lessonId(from: trimmed) else {
            return .invalid
        }

        let rows: [LessonQRRow] = try await client.from("lessons")
            .select()
            .eq("id", value: lessonId)
            .limit(1)
            .execute()
            .value

        guard let row = rows.first else { return .invalid }

        // Check if the parent module is locked for this user
        if let userId = try? await client.auth.session.user.id.uuidString {
            let moduleRows: [ModuleQRRow] = try await client.from("modules")
                .select()
                .eq("id", value: row.module_id)
                .limit(1)
                .execute()
                .value

            if let module = moduleRows.first, module.is_locked {
                // Check if user has explicit unlock
                let unlocks: [[String: String]] = try await client.from("user_module_unlocks")
                    .select("module_id")
                    .eq("user_id", value: userId)
                    .eq("module_id", value: module.id)
                    .execute()
                    .value

                if unlocks.isEmpty {
                    return .accessDenied
                }
            }
        }

        return .lesson(row.toDomain())
    }

    func resolveContent(qrPayload: String) async throws -> QRResolution {
        let r = try await resolveLesson(qrPayload: qrPayload)
        switch r {
        case .lesson(let l):
            return .lesson(l)
        case .accessDenied:
            return .accessDenied("Bu içerik için erişim izniniz yok.")
        case .invalid:
            return .invalid
        }
    }

    // MARK: - Parse QR Payload

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

// MARK: - Errors

enum QRError: LocalizedError {
    case invalidCode
    case moduleNotFound

    var errorDescription: String? {
        switch self {
        case .invalidCode:   return "Geçersiz QR kodu."
        case .moduleNotFound: return "Modül bulunamadı."
        }
    }
}

// MARK: - DB Row DTOs

private struct QRCodeRow: Codable {
    let module_id: String
}

private struct ModuleQRRow: Codable {
    let id: String
    let title: String
    let description: String
    let image_url: String?
    let is_locked: Bool
    let order: Int
    let lessons: [LessonQRRow]?

    func toDomain() -> CourseModule {
        CourseModule(
            id: id,
            title: title,
            description: description,
            imageURL: image_url.flatMap(URL.init(string:)),
            lessons: (lessons ?? [])
                .sorted { $0.order < $1.order }
                .map { $0.toDomain() },
            isLocked: is_locked
        )
    }
}

private struct LessonQRRow: Codable {
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
