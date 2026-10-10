import Foundation

struct Question: Codable, Identifiable, Hashable {
    let id: String
    var text: String
    var options: [String]
    var correctOptionIndex: Int
    var type: QuestionType

    private enum CodingKeys: String, CodingKey {
        case id, text, options, correctOptionIndex, type
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        options = try c.decode([String].self, forKey: .options)
        correctOptionIndex = try c.decode(Int.self, forKey: .correctOptionIndex)
        type = try c.decodeIfPresent(QuestionType.self, forKey: .type) ?? .multipleChoice
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(text, forKey: .text)
        try c.encode(options, forKey: .options)
        try c.encode(correctOptionIndex, forKey: .correctOptionIndex)
        try c.encode(type, forKey: .type)
    }

    init(id: String, text: String, options: [String], correctOptionIndex: Int, type: QuestionType = .multipleChoice) {
        self.id = id
        self.text = text
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.type = type
    }

    var isTrueFalse: Bool { type == .trueFalse }

    var displayTypeLabel: String {
        switch type {
        case .multipleChoice: return "Çoktan Seçmeli"
        case .trueFalse: return "Doğru / Yanlış"
        case .imageErrorFind: return "Görsel — Hata Bul"
        case .equipmentMatching: return "Ekipman Eşleştirme"
        case .needleCodeReading: return "İğne Kodu Okuma"
        }
    }

    var typeBadgeIcon: String {
        switch type {
        case .multipleChoice: return "list.bullet"
        case .trueFalse: return "hand.thumbsup"
        case .imageErrorFind: return "eye.trianglebadge.exclamationmark"
        case .equipmentMatching: return "wrench.and.screwdriver"
        case .needleCodeReading: return "number"
        }
    }
}

// MARK: - Question Type

enum QuestionType: String, Codable, Hashable {
    case multipleChoice
    case imageErrorFind
    case equipmentMatching
    case needleCodeReading
    case trueFalse
}
