import Foundation

struct Question: Codable, Identifiable, Hashable {
    let id: String
    var text: String
    var options: [String]
    var correctOptionIndex: Int
    var type: QuestionType

    /// Backward-compatible: defaults to `.multipleChoice` when absent in JSON.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        options = try c.decode([String].self, forKey: .options)
        correctOptionIndex = try c.decode(Int.self, forKey: .correctOptionIndex)
        type = try c.decodeIfPresent(QuestionType.self, forKey: .type) ?? .multipleChoice
    }

    /// Memberwise init for code usage.
    init(id: String, text: String, options: [String], correctOptionIndex: Int, type: QuestionType = .multipleChoice) {
        self.id = id
        self.text = text
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.type = type
    }

    var isTrueFalse: Bool { type == .trueFalse }
}

// MARK: - Question Type

enum QuestionType: String, Codable, Hashable {
    case multipleChoice
    case trueFalse
}
