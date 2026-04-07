import Foundation

struct Quiz: Codable, Identifiable, Hashable {
    let id: String
    var lessonId: String
    var questions: [Question]
    var passingScore: Int
}
