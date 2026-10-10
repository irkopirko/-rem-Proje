import SwiftUI

struct TattooMistakeResultView: View {
    @Bindable var viewModel: TattooMistakeGameViewModel
    let onPlayAgain: () -> Void
    let onReturnToGames: () -> Void
    let onShowAnswers: () -> Void
    let onCommitXP: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: viewModel.didWin ? "checkmark.seal.fill" : "clock.badge.exclamationmark.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(viewModel.didWin ? Color.inkSage : Color.inkWarning)

                    Text(viewModel.didWin ? "Tebrikler!" : "Süre Doldu")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.inkTextPrimary)

                    Text(viewModel.didWin
                         ? "Dövmedeki tüm hataları buldun."
                         : "Bazı hatalar gözünden kaçtı.")
                        .font(.subheadline)
                        .foregroundStyle(Color.inkTextSecondary)
                        .multilineTextAlignment(.center)

                    statsBlock

                    VStack(spacing: 10) {
                        InkButton(title: viewModel.didWin ? "Tekrar Oyna" : "Tekrar Dene") {
                            onPlayAgain()
                        }

                        if !viewModel.didWin {
                            InkButtonOutline(title: "Cevapları Gör") {
                                onShowAnswers()
                            }
                        }

                        InkButtonOutline(title: "Oyunlara Dön") {
                            onCommitXP()
                            onReturnToGames()
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 340)
                .background(Color.inkSurface)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                .padding(.horizontal, AppSpacing.screenH)
                .padding(.vertical, 40)
            }
        }
        .onAppear { onCommitXP() }
    }

    private var statsBlock: some View {
        VStack(spacing: 8) {
            statRow("Bulunan hata", "\(viewModel.foundCount) / \(viewModel.totalMistakes)")
            statRow("Kazanılan XP", "\(viewModel.score)")
            if viewModel.didWin {
                statRow("Kalan süre", viewModel.formattedTime)
            }
            if let difficulty = viewModel.selectedChallenge?.difficulty.rawValue {
                statRow("Zorluk", difficulty)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(Color.inkSurfaceSecondary.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.inkTextSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.inkTextPrimary)
        }
    }
}

#Preview {
    ZStack {
        Color.inkBackground.ignoresSafeArea()
        TattooMistakeResultView(
            viewModel: TattooMistakeGameViewModel(),
            onPlayAgain: {},
            onReturnToGames: {},
            onShowAnswers: {},
            onCommitXP: {}
        )
    }
}
