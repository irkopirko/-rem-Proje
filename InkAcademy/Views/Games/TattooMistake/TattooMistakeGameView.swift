import SwiftUI

struct TattooMistakeGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = TattooMistakeGameViewModel()
    var onAwardXP: ((Int) -> Void)? = nil

    var body: some View {
        Group {
            switch viewModel.phase {
            case .intro:
                TattooMistakeIntroView(viewModel: viewModel)
            case .playing:
                playingContent
            case .finished:
                playingContent
                    .overlay {
                        TattooMistakeResultView(
                            viewModel: viewModel,
                            onPlayAgain: { viewModel.startRandomChallenge() },
                            onReturnToGames: { dismiss() },
                            onShowAnswers: { viewModel.showReview() },
                            onCommitXP: { commitXP() }
                        )
                    }
            case .answerReview:
                if let challenge = viewModel.selectedChallenge {
                    TattooMistakeAnswerReviewView(
                        challenge: challenge,
                        foundMistakeIDs: viewModel.foundMistakeIDs,
                        onBack: { viewModel.returnToResult() }
                    )
                }
            }
        }
        .navigationTitle("Dövmedeki Hataları Bul")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear { viewModel.prepareIntro() }
        .onDisappear { viewModel.cleanup() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                viewModel.resumeGame()
            case .background, .inactive:
                viewModel.pauseGame()
            @unknown default:
                break
            }
        }
    }

    private var playingContent: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("XP: \(viewModel.score)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, AppSpacing.screenH)
            .padding(.top, 4)

            infoBar
                .padding(.horizontal, AppSpacing.screenH)
                .padding(.top, 8)
                .padding(.bottom, 8)

            instructionBlock
                .padding(.horizontal, AppSpacing.screenH)
                .padding(.bottom, 10)

            if let challenge = viewModel.selectedChallenge {
                TattooMistakeSceneView(
                    challenge: challenge,
                    foundMistakeIDs: viewModel.foundMistakeIDs,
                    highlightedMistakeID: viewModel.highlightedMistakeID,
                    wrongTapPoint: viewModel.wrongTapPoint,
                    showWrongTap: viewModel.showWrongTap,
                    revealAllMistakes: false
                ) { point, size in
                    viewModel.handleTap(at: point, sceneSize: size)
                }
                .padding(.horizontal, AppSpacing.screenH)

                mistakeChecklist(challenge: challenge)
                    .padding(.horizontal, AppSpacing.screenH)
                    .padding(.vertical, 14)
            }

            Spacer(minLength: 0)
        }
        .inkPageBackground()
    }

    private var infoBar: some View {
        HStack {
            CountdownTimerView(
                timeText: viewModel.formattedTime,
                isUrgent: viewModel.remainingTime <= 10 && viewModel.phase == .playing
            )
            Spacer()
            MistakeProgressView(found: viewModel.foundCount, total: viewModel.totalMistakes)
        }
    }

    private var instructionBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.selectedChallenge?.instruction ?? "Görseldeki hatalı bölgeleri bul.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkTextPrimary)
            Text("Hatalı olduğunu düşündüğün alana dokun.")
                .font(.caption)
                .foregroundStyle(Color.inkTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func mistakeChecklist(challenge: TattooMistakeChallenge) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bulman gereken hatalar")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.inkTextPrimary)

            ForEach(Array(challenge.mistakes.enumerated()), id: \.element.id) { _, mistake in
                HStack(spacing: 10) {
                    if viewModel.isFound(mistake) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.inkSage)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(Color.inkTextTertiary)
                    }
                    Text(mistake.title)
                        .font(.subheadline.weight(viewModel.isFound(mistake) ? .semibold : .regular))
                        .foregroundStyle(viewModel.isFound(mistake) ? Color.inkTextPrimary : Color.inkTextSecondary)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding(AppSpacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func commitXP() {
        viewModel.commitXPIfNeeded { xp in
            onAwardXP?(xp)
        }
    }
}

#Preview {
    NavigationStack {
        TattooMistakeGameView()
    }
}
