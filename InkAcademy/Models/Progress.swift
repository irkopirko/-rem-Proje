import Foundation

struct Progress: Codable, Identifiable, Hashable {
    var id: String { "\(userId)-\(moduleId)" }
    var userId: String
    var moduleId: String
    var completedLessonIds: Set<String>
    var quizScores: [String: Int]

    var overallPercent: Double {
        guard !completedLessonIds.isEmpty else { return 0 }
        return Double(completedLessonIds.count)
    }
}
