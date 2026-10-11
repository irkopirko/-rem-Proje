import SwiftUI

/// Weekly hidden-object mini game — modular entry point.
struct HiddenObjectGame: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: HiddenObjectGameViewModel
    var onComplete: ((Int) -> Void)?

    init(config: HiddenObjectGameConfig = .standard, onComplete: ((Int) -> Void)? = nil) {
        _viewModel = State(initialValue: HiddenObjectGameViewModel(config: config))
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, AppSpacing.screenH)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                GameScene(
                    sceneAsset: viewModel.config.imageSet.scene,
                    imageSet: viewModel.config.imageSet,
                    objects: viewModel.objects,
                    wrongTapPoint: viewModel.wrongTapPoint,
                    showWrongTap: viewModel.showWrongTap
                ) { point, size in
                    viewModel.handleTap(at: point, sceneSize: size)
                }
                .padding(.horizontal, AppSpacing.screenH)

                BottomObjectBar(
                    foundTypes: viewModel.foundTypes,
                    imageSet: viewModel.config.imageSet
                )
                .padding(.horizontal, AppSpacing.screenH)
                .padding(.vertical, 14)
            }
            .studentScreenBackground()

            if viewModel.phase != .playing {
                endOverlay
            }
        }
        .navigationTitle("Günün Oyunu")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.startGame() }
        .onDisappear { viewModel.exitGame() }
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase == .won {
                onComplete?(viewModel.score)
            }
        }
    }

    private var headerBar: some View {
        HStack {
            GameTimer(timeText: viewModel.formattedTime)
            Spacer()
            GameScore(score: viewModel.score, maxScore: viewModel.config.maxScore)
        }
    }

    private var endOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: viewModel.phase == .won ? "checkmark.seal.fill" : "clock.badge.exclamationmark.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(viewModel.phase == .won ? Color.inkSage : Color.inkWarning)

                Text(viewModel.phase == .won ? "Congratulations!" : "Time's Up!")
                    .font(AppTypography.sectionHeading())
                    .foregroundStyle(InkMockup.textPrimary)

                Text(viewModel.phase == .won ? "You found all hidden objects." : "Try Again.")
                    .font(AppTypography.body())
                    .foregroundStyle(InkMockup.captionColor)
                    .multilineTextAlignment(.center)

                if viewModel.phase == .won {
                    Text("Score: \(viewModel.score) / \(viewModel.config.maxScore)")
                        .font(AppTypography.monoMedium(size: 13))
                        .tracking(1.0)
                        .foregroundStyle(InkMockup.accentPink)
                }

                VStack(spacing: 10) {
                    Button("Play Again") {
                        viewModel.startGame()
                    }
                    .buttonStyle(InkPrimaryButtonStyle())

                    Button("Exit") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(Color.inkTextSecondary)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .glassChrome(radius: 24, emphasized: true)
        }
    }
}

#Preview {
    NavigationStack {
        HiddenObjectGame()
    }
}
