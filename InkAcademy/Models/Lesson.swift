import Foundation

struct Lesson: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var videoURL: URL?
    var duration: TimeInterval
    var order: Int
    var isCompleted: Bool
    var description: String

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
