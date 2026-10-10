import Foundation

enum QRContentKind: String, Codable, Hashable {
    case lesson
    case module
    case product
    case bookPage
    case kitContent
}

struct QRContent: Identifiable, Hashable, Codable {
    let id: String
    var type: QRContentKind
    var title: String
    var targetId: String
    var description: String
}
