import Foundation
import SwiftUI

@Observable
@MainActor
final class HiddenObjectGameViewModel {
    var objects: [PlacedHiddenObject] = []
    var score: Int = 0
    var remainingSeconds: Int = HiddenObjectGameConfig.durationSeconds
    var phase: HiddenObjectGamePhase = .playing
    var wrongTapPoint: CGPoint?
    var showWrongTap = false

    private var timerTask: Task<Void, Never>?

    var formattedTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var foundTypes: Set<HiddenObjectType> {
        Set(objects.filter(\.isFound).map(\.type))
    }

    func startGame() {
        cancelTimer()
        objects = HiddenObjectPlacementEngine.generate()
        score = 0
        remainingSeconds = HiddenObjectGameConfig.durationSeconds
        phase = .playing
        wrongTapPoint = nil
        showWrongTap = false
        startTimer()
    }

    func handleTap(at point: CGPoint, sceneSize: CGSize) {
        guard phase == .playing, sceneSize.width > 0, sceneSize.height > 0 else { return }

        if let index = objects.firstIndex(where: { !$0.isFound && $0.contains(point, in: sceneSize) }) {
            objects[index].isFound = true
            objects[index].isHighlighted = true
            score += objects[index].type.points

            Task {
                try? await Task.sleep(for: .milliseconds(450))
                if index < objects.count {
                    objects[index].isHighlighted = false
                }
            }

            if objects.allSatisfy(\.isFound) {
                endGame(won: true)
            }
        } else {
            wrongTapPoint = point
            showWrongTap = true
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                showWrongTap = false
                wrongTapPoint = nil
            }
        }
    }

    func exitGame() {
        cancelTimer()
    }

    private func startTimer() {
        timerTask = Task {
            while !Task.isCancelled, remainingSeconds > 0, phase == .playing {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, phase == .playing else { return }
                remainingSeconds -= 1
                if remainingSeconds == 0 {
                    endGame(won: objects.allSatisfy(\.isFound))
                }
            }
        }
    }

    private func endGame(won: Bool) {
        cancelTimer()
        phase = won ? .won : .lost
    }

    private func cancelTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}
