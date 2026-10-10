import SwiftUI

struct TattooMistakeIntroView: View {
    @Bindable var viewModel: TattooMistakeGameViewModel
    @State private var showHowToPlay = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Dövmedeki Hataları Bul")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.inkTextPrimary)

                    Text("Görseldeki uygulama hatalarını süre dolmadan bul. Hatalı olduğunu düşündüğün bölgelere dokun.")
                        .font(.subheadline)
                        .foregroundStyle(Color.inkTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                rulesCard

                InkButton(title: "Oyuna Başla") {
                    viewModel.startRandomChallenge()
                }

                Button {
                    showHowToPlay = true
                } label: {
                    Text("Nasıl Oynanır?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.inkAccent)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.screenH)
            .padding(.vertical, AppSpacing.lg)
        }
        .inkPageBackground()
        .alert("Nasıl Oynanır?", isPresented: $showHowToPlay) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Dövme görselindeki hatalı bölgelere dokun. Her doğru buluş +5 XP kazandırır. Yanlış dokunuş puan düşürmez. Süre dolmadan tüm hataları bulmaya çalış.")
        }
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kurallar")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.inkTextPrimary)

            ruleRow("Her doğru hata: +5 XP")
            ruleRow("Yanlış dokunuş: puan düşürmez")
            ruleRow("Bulunan hata tekrar seçilemez")
            ruleRow("Süre dolmadan bütün hataları bul")
            ruleRow("Toplam hata sayısı oyun başında gösterilir")
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.inkSurface.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous)
                .stroke(Color.inkBorder, lineWidth: 1)
        )
    }

    private func ruleRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(Color.inkAccent)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.inkTextSecondary)
        }
    }
}

#Preview {
    TattooMistakeIntroView(viewModel: TattooMistakeGameViewModel())
}
