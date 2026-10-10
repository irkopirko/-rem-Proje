import Foundation

enum PracticeTaskType: String, CaseIterable, Codable, Hashable {
    case stencil
    case drawing
    case fakeSkin
    case needleControl
    case shading
    case colorPacking
}

enum PracticeTaskStatus: String, CaseIterable, Codable, Hashable {
    case pending
    case submitted
    case reviewed
}

struct PracticeTask: Identifiable, Hashable, Codable {
    let id: String
    var title: String
    var description: String
    var type: PracticeTaskType
    var relatedModuleId: String
    var requiredUploadType: String
    var xpReward: Int
    var status: PracticeTaskStatus
}
