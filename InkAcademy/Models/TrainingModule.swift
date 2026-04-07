import Foundation

struct TrainingModule: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var description: String
    var imageURL: URL?
    var lessons: [Lesson]
    var isLocked: Bool

    var completedLessonsCount: Int {
        lessons.filter(\.isCompleted).count
    }

    var progressPercent: Double {
        guard !lessons.isEmpty else { return 0 }
        return Double(completedLessonsCount) / Double(lessons.count)
    }
}
