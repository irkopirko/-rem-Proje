import Foundation

/// QR çözümleme sonucu — ders dışı içerik türleri Supabase ile genişletilebilir.
enum QRResolution: Equatable {
    case lesson(Lesson)
    case module(CourseModule)
    case product(InkProduct)
    case bookPage(QRContent)
    case kitContent(QRContent)
    case invalid
    case accessDenied(String)
}
