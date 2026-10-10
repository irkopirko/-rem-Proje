import SwiftUI

struct HiddenObjectGameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = HiddenObjectGameViewModel()
    var onComplete: ((Int) -> Void)? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, AppSpacing.screenH)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                GameScene(
                    objects: viewModel.objects,
                    wrongTapPoint: viewModel.wrongTapPoint,
                    showWrongTap: viewModel.showWrongTap
                ) { point, size in
                    viewModel.handleTap(at: point, sceneSize: size)
                }
                .padding(.horizontal, AppSpacing.screenH)

                BottomObjectBar(foundTypes: viewModel.foundTypes)
                    .padding(.horizontal, AppSpacing.screenH)
                    .padding(.vertical, 14)
            }
            .inkPageBackground()

            if viewModel.phase != .playing {
                endOverlay
            }
        }
        .navigationTitle("Gizli Nesne")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
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
            GameTimerView(timeText: viewModel.formattedTime)
            Spacer()
            GameScoreView(score: viewModel.score)
        }
    }

    private var endOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: viewModel.phase == .won ? "checkmark.seal.fill" : "clock.badge.exclamationmark.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(viewModel.phase == .won ? Color.inkSage : Color.inkWarning)

                Text(viewModel.phase == .won ? "Tebrikler!" : "Süre Doldu!")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.inkTextPrimary)

                Text(viewModel.phase == .won ? "Tüm gizli nesneleri buldun." : "Tekrar dene.")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkTextSecondary)
                    .multilineTextAlignment(.center)

                if viewModel.phase == .won {
                    Text("+\(viewModel.score) puan")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.inkAccent)
                }

                VStack(spacing: 10) {
                    InkButton(title: "Tekrar Oyna") {
                        viewModel.startGame()
                    }

                    InkButtonOutline(title: "Çık") {
                        dismiss()
                    }
                }
                .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(Color.inkSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
    }
}

#Preview {
    NavigationStack {
        HiddenObjectGameView()
    }
}
