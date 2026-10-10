import Foundation
import SwiftUI
import UIKit

@Observable
@MainActor
final class TattooMistakeGameViewModel {
    var phase: TattooMistakeGamePhase = .intro
    var selectedChallenge: TattooMistakeChallenge?
    var remainingTime: Int = 0
    var foundMistakeIDs: Set<UUID> = []
    var score: Int = 0
    var isGameActive = false
    var isGameFinished = false
    var didWin = false
    var wrongTapPoint: CGPoint?
    var showWrongTap = false
    var highlightedMistakeID: UUID?
    var showAnswerReview = false
    var xpCommitted = false

    private var timerTask: Task<Void, Never>?
    private var lastChallengeID: UUID?
    private let hapticSuccess = UINotificationFeedbackGenerator()
    private let hapticError = UINotificationFeedbackGenerator()

    var formattedTime: String {
        let m = remainingTime / 60
        let s = remainingTime % 60
        return String(format: "%02d:%02d", m, s)
    }

    var foundCount: Int { foundMistakeIDs.count }
    var totalMistakes: Int { selectedChallenge?.mistakeCount ?? 0 }

    func prepareIntro() {
        phase = .intro
        resetSessionState()
    }

    func startRandomChallenge() {
        cancelTimer()
        let challenge = TattooMistakeChallengeCatalog.randomChallenge(excluding: lastChallengeID)
        lastChallengeID = challenge.id
        selectedChallenge = challenge
        remainingTime = challenge.timeLimit
        foundMistakeIDs = []
        score = 0
        isGameActive = true
        isGameFinished = false
        didWin = false
        showAnswerReview = false
        xpCommitted = false
        wrongTapPoint = nil
        showWrongTap = false
        highlightedMistakeID = nil
        phase = .playing
        startTimer()
    }

    func handleTap(at point: CGPoint, sceneSize: CGSize) {
        guard phase == .playing,
              isGameActive,
              let challenge = selectedChallenge,
              sceneSize.width > 0,
              sceneSize.height > 0 else { return }

        if let mistake = challenge.mistakes.first(where: { m in
            !foundMistakeIDs.contains(m.id) && m.contains(point, in: sceneSize)
        }) {
            foundMistakeIDs.insert(mistake.id)
            score += TattooMistakeGameConstants.xpPerMistake
            highlightedMistakeID = mistake.id
            hapticSuccess.notificationOccurred(.success)

            Task {
                try? await Task.sleep(for: .milliseconds(500))
                if highlightedMistakeID == mistake.id {
                    highlightedMistakeID = nil
                }
            }

            if foundMistakeIDs.count == challenge.mistakeCount {
                finishGame(won: true)
            }
        } else {
            wrongTapPoint = point
            showWrongTap = true
            hapticError.notificationOccurred(.error)
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                showWrongTap = false
                wrongTapPoint = nil
            }
        }
    }

    func pauseGame() {
        guard isGameActive, phase == .playing else { return }
        cancelTimer()
    }

    func resumeGame() {
        guard isGameActive, phase == .playing, remainingTime > 0 else { return }
        startTimer()
    }

    func showReview() {
        showAnswerReview = true
        phase = .answerReview
    }

    func returnToResult() {
        showAnswerReview = false
        phase = .finished
    }

    func commitXPIfNeeded(onAward: (Int) -> Void) {
        guard !xpCommitted, isGameFinished else { return }
        xpCommitted = true
        onAward(score)
    }

    func cleanup() {
        cancelTimer()
        isGameActive = false
    }

    func mistake(at index: Int) -> TattooMistake? {
        guard let challenge = selectedChallenge,
              index >= 0,
              index < challenge.mistakes.count else { return nil }
        return challenge.mistakes[index]
    }

    func isFound(_ mistake: TattooMistake) -> Bool {
        foundMistakeIDs.contains(mistake.id)
    }

    private func finishGame(won: Bool) {
        cancelTimer()
        isGameActive = false
        isGameFinished = true
        didWin = won
        phase = .finished
    }

    private func startTimer() {
        cancelTimer()
        timerTask = Task {
            while !Task.isCancelled, remainingTime > 0, isGameActive, phase == .playing {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, isGameActive, phase == .playing else { return }
                remainingTime -= 1
                if remainingTime == 0 {
                    let won = foundMistakeIDs.count == (selectedChallenge?.mistakeCount ?? 0)
                    finishGame(won: won)
                }
            }
        }
    }

    private func cancelTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func resetSessionState() {
        cancelTimer()
        selectedChallenge = nil
        remainingTime = 0
        foundMistakeIDs = []
        score = 0
        isGameActive = false
        isGameFinished = false
        didWin = false
        showAnswerReview = false
        xpCommitted = false
    }
}
