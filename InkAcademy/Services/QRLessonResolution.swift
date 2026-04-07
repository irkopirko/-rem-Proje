import Foundation

enum QRLessonResolution: Equatable {
    case lesson(Lesson)
    case invalid
    case accessDenied
}
