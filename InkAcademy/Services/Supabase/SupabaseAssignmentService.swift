import Foundation
import Supabase

final class SupabaseAssignmentService: AssignmentServiceProtocol {
    private let client = SupabaseManager.client

    // MARK: - Fetch Assignments

    func fetchAssignments() async throws -> [Assignment] {
        guard let userId = try? await client.auth.session.user.id.uuidString else { return [] }

        let rows: [AssignmentRow] = try await client.from("assignments")
            .select("*, feedback:feedbacks(*)")
            .eq("user_id", value: userId)
            .order("due_date", ascending: true)
            .execute()
            .value

        return rows.map { $0.toDomain() }
    }

    // MARK: - Upload Assignment

    func uploadAssignment(id: String, fileURL: URL) async throws -> Assignment {
        guard let userId = try? await client.auth.session.user.id.uuidString else {
            throw AssignmentError.uploadFailed
        }

        // 1. Upload file to Supabase Storage
        let fileData = try Data(contentsOf: fileURL)
        let ext = fileURL.pathExtension
        let storagePath = "\(userId)/\(id).\(ext)"

        _ = try await client.storage
            .from("assignments")
            .upload(
                storagePath,
                data: fileData,
                options: FileOptions(contentType: mimeType(for: ext), upsert: true)
            )

        // 2. Get public URL
        let publicURL = try client.storage
            .from("assignments")
            .getPublicURL(path: storagePath)

        // 3. Update the assignment row
        try await client.from("assignments")
            .update([
                "file_url": publicURL.absoluteString,
                "status": "submitted",
                "submission_date": ISO8601DateFormatter().string(from: .now)
            ])
            .eq("id", value: id)
            .execute()

        // 4. Re-fetch and return updated assignment
        let rows: [AssignmentRow] = try await client.from("assignments")
            .select("*, feedback:feedbacks(*)")
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value

        guard let row = rows.first else { throw AssignmentError.notFound }
        return row.toDomain()
    }

    // MARK: - Fetch Feedback

    func fetchFeedback(assignmentId: String) async throws -> Feedback? {
        let rows: [FeedbackRow] = try await client.from("feedbacks")
            .select()
            .eq("assignment_id", value: assignmentId)
            .limit(1)
            .execute()
            .value

        return rows.first?.toDomain()
    }

    // MARK: - Helpers

    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "pdf": return "application/pdf"
        case "heic": return "image/heic"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - DB Row DTOs

private struct AssignmentRow: Codable {
    let id: String
    let title: String
    let description: String
    let due_date: String
    let submission_date: String?
    let file_url: String?
    let status: String
    let feedback: [FeedbackRow]?

    func toDomain() -> Assignment {
        let iso = ISO8601DateFormatter()
        return Assignment(
            id: id,
            title: title,
            description: description,
            dueDate: iso.date(from: due_date) ?? .now,
            submissionDate: submission_date.flatMap { iso.date(from: $0) },
            fileURL: file_url.flatMap(URL.init(string:)),
            status: Assignment.Status(rawValue: status) ?? .pending,
            feedback: feedback?.first?.toDomain()
        )
    }
}

private struct FeedbackRow: Codable {
    let id: String
    let assignment_id: String
    let instructor_id: String
    let instructor_name: String
    let comment: String
    let rating: Int
    let date: String

    func toDomain() -> Feedback {
        let iso = ISO8601DateFormatter()
        return Feedback(
            id: id,
            assignmentId: assignment_id,
            instructorId: instructor_id,
            instructorName: instructor_name,
            comment: comment,
            rating: rating,
            date: iso.date(from: date) ?? .now
        )
    }
}
