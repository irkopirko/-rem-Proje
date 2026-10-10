import Foundation
import CoreGraphics

enum TattooMistakeDifficulty: String, Codable, CaseIterable, Hashable {
    case easy = "Kolay"
    case medium = "Orta"
    case hard = "Zor"
}

struct TattooMistake: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let shortExplanation: String
    let normalizedX: CGFloat
    let normalizedY: CGFloat
    let normalizedWidth: CGFloat
    let normalizedHeight: CGFloat

    init(
        id: UUID = UUID(),
        title: String,
        shortExplanation: String,
        normalizedX: CGFloat,
        normalizedY: CGFloat,
        normalizedWidth: CGFloat,
        normalizedHeight: CGFloat
    ) {
        self.id = id
        self.title = title
        self.shortExplanation = shortExplanation
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.normalizedWidth = normalizedWidth
        self.normalizedHeight = normalizedHeight
    }

    /// Normalized rect with origin at top-left.
    var normalizedRect: CGRect {
        CGRect(
            x: normalizedX - normalizedWidth / 2,
            y: normalizedY - normalizedHeight / 2,
            width: normalizedWidth,
            height: normalizedHeight
        )
    }

    func rect(in sceneSize: CGSize) -> CGRect {
        let n = normalizedRect
        return CGRect(
            x: n.origin.x * sceneSize.width,
            y: n.origin.y * sceneSize.height,
            width: n.width * sceneSize.width,
            height: n.height * sceneSize.height
        )
    }

    func contains(_ point: CGPoint, in sceneSize: CGSize) -> Bool {
        rect(in: sceneSize).contains(point)
    }
}

struct TattooMistakeChallenge: Identifiable, Hashable, Codable {
    let id: UUID
    let imageName: String
    let title: String
    let instruction: String
    let timeLimit: Int
    let difficulty: TattooMistakeDifficulty
    let mistakes: [TattooMistake]

    var mistakeCount: Int { mistakes.count }

    var completionXP: Int { mistakes.count * 5 }
}

enum TattooMistakeGamePhase: Equatable {
    case intro
    case playing
    case finished
    case answerReview
}

struct TattooMistakeGameConstants {
    static let xpPerMistake = 5
}
