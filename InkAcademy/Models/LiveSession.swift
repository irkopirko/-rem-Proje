import Foundation

struct LiveSession: Identifiable, Hashable, Codable {
    let id: String
    var title: String
    var description: String
    var startDate: Date
    var instructorName: String
    var meetingURL: URL?
    var isReplayAvailable: Bool
    var replayURL: URL?
}
