import SwiftUI

struct TattooMistakeAnswerReviewView: View {
    let challenge: TattooMistakeChallenge
    let foundMistakeIDs: Set<UUID>
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                Text("Cevaplar & Açıklamalar")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.inkTextPrimary)

                Text("Eğitim amaçlı uygulama hatası değerlendirmesidir; tıbbi teşhis değildir.")
                    .font(.caption)
                    .foregroundStyle(Color.inkTextTertiary)

                TattooMistakeSceneView(
                    challenge: challenge,
                    foundMistakeIDs: foundMistakeIDs,
                    highlightedMistakeID: nil,
                    wrongTapPoint: nil,
                    showWrongTap: false,
                    revealAllMistakes: true
                ) { _, _ in }
                .frame(height: 360)

                VStack(spacing: 12) {
                    ForEach(challenge.mistakes) { mistake in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: foundMistakeIDs.contains(mistake.id) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(foundMistakeIDs.contains(mistake.id) ? Color.inkSage : Color.inkWarning)
                                Text(mistake.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color.inkTextPrimary)
                            }
                            Text(mistake.shortExplanation)
                                .font(.footnote)
                                .foregroundStyle(Color.inkTextSecondary)
                        }
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.inkSurface.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                InkButtonOutline(title: "Sonuç Ekranına Dön") {
                    onBack()
                }
            }
            .padding(.horizontal, AppSpacing.screenH)
            .padding(.vertical, AppSpacing.lg)
        }
        .inkPageBackground()
        .navigationTitle("Cevaplar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TattooMistakeAnswerReviewView(
            challenge: TattooMistakeChallengeCatalog.mainChallenge,
            foundMistakeIDs: [],
            onBack: {}
        )
    }
}
