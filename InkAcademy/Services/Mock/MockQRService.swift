import Foundation

final class MockQRService: QRServiceProtocol {
    private let accessDeniedLessonIds: Set<String> = ["lesson-2-2", "lesson-3-1"]
    private let ecosystem = MockEcosystemCatalogService()

    func unlockModule(qrPayload: String) async throws -> CourseModule {
        try await Task.sleep(for: .seconds(1))
        return CourseModule(
            id: qrPayload,
            title: "Kilidi Açılan Modül",
            description: "Bu modül QR kod ile açılmıştır.",
            imageURL: nil,
            lessons: [],
            isLocked: false
        )
    }

    func resolveLesson(qrPayload: String) async throws -> QRLessonResolution {
        let r = try await resolveContent(qrPayload: qrPayload)
        switch r {
        case .lesson(let lesson):
            return .lesson(lesson)
        case .accessDenied:
            return .accessDenied
        default:
            return .invalid
        }
    }

    func resolveContent(qrPayload: String) async throws -> QRResolution {
        try await Task.sleep(for: .milliseconds(500))
        let trimmed = qrPayload.trimmingCharacters(in: .whitespacesAndNewlines)
        let u = trimmed.uppercased()

        if u.hasPrefix("INK-PRODUCT-") {
            let products = await ecosystem.fetchProducts()
            let suffix = u.replacingOccurrences(of: "INK-PRODUCT-", with: "")
            if let p = products.first(where: {
                $0.id.localizedCaseInsensitiveContains(suffix)
                    || suffix.localizedCaseInsensitiveContains($0.id.replacingOccurrences(of: "prod_", with: ""))
            }) {
                return .product(p)
            }
            if suffix.contains("0807") {
                if let p = products.first(where: { $0.id == "prod_needle_0807rl" }) { return .product(p) }
            }
            return .invalid
        }

        if u.hasPrefix("INK-BOOK-") {
            let content = QRContent(
                id: "book_" + u,
                type: .bookPage,
                title: "Kitap içeriği",
                targetId: trimmed,
                description: "Mock kitap / QR sayfası — Supabase ile içerik bağlanacak."
            )
            return .bookPage(content)
        }

        if u.hasPrefix("INK-KIT-") {
            let content = QRContent(
                id: "kit_" + u,
                type: .kitContent,
                title: "Eğitim seti içeriği",
                targetId: trimmed,
                description: "Mock kit içeriği — premium starter içerikleri."
            )
            return .kitContent(content)
        }

        if u.hasPrefix("INK-MODULE-") {
            let id = String(trimmed.dropFirst("INK-MODULE-".count))
            let modules = try MockDataLoader.load("modules", as: [CourseModule].self)
            if let m = modules.first(where: { $0.id == id }) { return .module(m) }
            return .invalid
        }

        if u.hasPrefix("INK-LESSON-") {
            let modules = try MockDataLoader.load("modules", as: [CourseModule].self)
            if u.contains("LINE") {
                if let l = modules.flatMap(\.lessons).first(where: { $0.id == "lesson-3-1" }) {
                    return .lesson(l)
                }
            }
            let fakePayload = trimmed
                .replacingOccurrences(of: "INK-LESSON-", with: "INKA:", options: .caseInsensitive)
            if let lessonId = Self.lessonId(from: fakePayload) {
                if accessDeniedLessonIds.contains(lessonId) || trimmed.uppercased().hasPrefix("INKA-PRO:") {
                    return .accessDenied("Bu ders için erişim izniniz yok.")
                }
                let lessons = modules.flatMap(\.lessons)
                if let lesson = lessons.first(where: { $0.id == lessonId }) {
                    return .lesson(lesson)
                }
            }
        }

        let legacy = try await legacyResolve(trimmed: trimmed)
        switch legacy {
        case .lesson(let l): return .lesson(l)
        case .accessDenied: return .accessDenied("Bu ders için erişim izniniz yok.")
        case .invalid: return .invalid
        }
    }

    private func legacyResolve(trimmed: String) async throws -> QRLessonResolution {
        guard let lessonId = Self.lessonId(from: trimmed) else {
            return .invalid
        }
        if accessDeniedLessonIds.contains(lessonId) || trimmed.hasPrefix("INKA-PRO:") {
            return .accessDenied
        }
        let modules = try MockDataLoader.load("modules", as: [CourseModule].self)
        let lessons = modules.flatMap(\.lessons)
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
