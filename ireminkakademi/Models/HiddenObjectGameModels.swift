import Foundation
import CoreGraphics

enum HiddenObjectType: String, CaseIterable, Identifiable, Hashable {
    case machine
    case needle
    case ink

    var id: String { rawValue }

    func assetName(in set: HiddenObjectImageSet) -> String {
        switch self {
        case .machine: return set.machine
        case .needle: return set.needle
        case .ink: return set.ink
        }
    }

    var title: String {
        switch self {
        case .machine: return "Dövme Makinesi"
        case .needle: return "İğne"
        case .ink: return "Mürekkep"
        }
    }

    var points: Int { 5 }

    /// Width / height — proportions preserved when scaling.
    var aspectRatio: CGFloat {
        switch self {
        case .machine: return 0.35
        case .needle: return 2.4
        case .ink: return 0.28
        }
    }
}

/// Swap asset catalog names to use any background + PNG objects you add.
struct HiddenObjectImageSet: Equatable {
    var scene: String
    var machine: String
    var needle: String
    var ink: String

    static let `default` = HiddenObjectImageSet(
        scene: "HiddenObjectScene",
        machine: "HiddenObjectMachine",
        needle: "HiddenObjectNeedle",
        ink: "HiddenObjectInk"
    )
}

struct PlacedHiddenObject: Identifiable {
    let id: UUID
    let type: HiddenObjectType
    /// Normalized center in scene (0…1).
    var center: CGPoint
    var rotation: Double
    var scale: CGFloat
    var baseWidthFraction: CGFloat
    var isFound: Bool
    var isHighlighted: Bool

    func frameSize(in sceneSize: CGSize) -> CGSize {
        let width = sceneSize.width * baseWidthFraction * scale
        let height = width / type.aspectRatio
        return CGSize(width: width, height: height)
    }

    func contains(_ point: CGPoint, in sceneSize: CGSize) -> Bool {
        let centerPoint = CGPoint(x: center.x * sceneSize.width, y: center.y * sceneSize.height)
        let size = frameSize(in: sceneSize)
        let dx = point.x - centerPoint.x
        let dy = point.y - centerPoint.y
        let radians = -rotation * .pi / 180
        let cosA = cos(radians)
        let sinA = sin(radians)
        let localX = dx * cosA - dy * sinA
        let localY = dx * sinA + dy * cosA
        return abs(localX) <= size.width / 2 && abs(localY) <= size.height / 2
    }
}

enum HiddenObjectGamePhase: Equatable {
    case playing
    case won
    case lost
}

struct HiddenObjectGameConfig {
    var imageSet: HiddenObjectImageSet
    var durationSeconds: Int
    var pointsPerObject: Int

    static let standard = HiddenObjectGameConfig(
        imageSet: .default,
        durationSeconds: 60,
        pointsPerObject: 5
    )

    var maxScore: Int { pointsPerObject * HiddenObjectType.allCases.count }
}

enum HiddenObjectPlacementEngine {
    static func generate(
        config: HiddenObjectGameConfig = .standard,
        objects: [HiddenObjectType] = HiddenObjectType.allCases
    ) -> [PlacedHiddenObject] {
        var placed: [PlacedHiddenObject] = []
        let padding: CGFloat = 0.06

        for type in objects {
            var success = false
            for _ in 0..<300 {
                let scale = CGFloat.random(in: 0.8...1.2)
                let rotation = Double.random(in: -15...15)
                let baseWidth = CGFloat.random(in: 0.10...0.15)
                let size = CGSize(width: baseWidth * scale, height: baseWidth * scale / type.aspectRatio)
                let halfW = size.width / 2
                let halfH = size.height / 2

                guard halfW + padding < 0.5, halfH + padding < 0.5 else { continue }

                let x = CGFloat.random(in: (halfW + padding)...(1 - halfW - padding))
                let y = CGFloat.random(in: (halfH + padding)...(1 - halfH - padding))
                let candidate = PlacedHiddenObject(
                    id: UUID(),
                    type: type,
                    center: CGPoint(x: x, y: y),
                    rotation: rotation,
                    scale: scale,
                    baseWidthFraction: baseWidth,
                    isFound: false,
                    isHighlighted: false
                )

                if !overlaps(candidate, others: placed) {
                    placed.append(candidate)
                    success = true
                    break
                }
            }

            if !success {
                let index = placed.count
                let x = min(0.75, 0.22 + CGFloat(index) * 0.28)
                placed.append(
                    PlacedHiddenObject(
                        id: UUID(),
                        type: type,
                        center: CGPoint(x: x, y: 0.5),
                        rotation: Double.random(in: -10...10),
                        scale: 1.0,
                        baseWidthFraction: 0.12,
                        isFound: false,
                        isHighlighted: false
                    )
                )
            }
        }

        return placed
    }

    private static func overlaps(_ candidate: PlacedHiddenObject, others: [PlacedHiddenObject]) -> Bool {
        let unitScene = CGSize(width: 1, height: 1)
        let a = candidate.frameSize(in: unitScene)
        let ax = candidate.center.x
        let ay = candidate.center.y

        for other in others {
            let b = other.frameSize(in: unitScene)
            let bx = other.center.x
            let by = other.center.y
            let gap: CGFloat = 0.025
            if abs(ax - bx) * 2 < (a.width + b.width) + gap,
               abs(ay - by) * 2 < (a.height + b.height) + gap {
                return true
            }
        }
        return false
    }
}
