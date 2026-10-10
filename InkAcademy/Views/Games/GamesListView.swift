import SwiftUI

struct GamesListView: View {
    var userProgress: UserProgressController?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                Text("XP kazanmak için günlük oyunlarını oyna.")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkTextSecondary)

                gameCard(
                    title: "Gizli Nesne",
                    subtitle: "Sahnedeki 3 dövme ekipmanını 30 saniyede bul. Her nesne 5 puan.",
                    icon: "magnifyingglass",
                    game: .hiddenObject
                )

                gameCard(
                    title: "Dövmedeki Hataları Bul",
                    subtitle: "Dövme görselindeki uygulama hatalarını süre dolmadan bul. Her hata +5 XP.",
                    icon: "eye.trianglebadge.exclamationmark",
                    game: .tattooMistake
                )
            }
            .padding(.horizontal, AppSpacing.screenH)
            .padding(.vertical, AppSpacing.lg)
        }
        .inkPageBackground()
        .navigationTitle("Oyunlar")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .onAppear { WeeklyActivityTracker.recordPlayToday() }
    }

    @ViewBuilder
    private func gameCard(
        title: String,
        subtitle: String,
        icon: String,
        game: GameDestination,
        isComingSoon: Bool = false
    ) -> some View {
        let content = HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.inkAccentSoft)
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.inkAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.inkTextPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if isComingSoon {
                Text("Yakında")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.inkAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.inkAccentSoft)
                    .clipShape(Capsule())
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.inkTextTertiary)
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.inkSurface.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous)
                .stroke(Color.inkBorder, lineWidth: 1)
        )

        if !isComingSoon {
            NavigationLink(value: game) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content.opacity(0.75)
        }
    }
}

#Preview {
    NavigationStack {
        GamesListView(userProgress: UserProgressController())
            .navigationDestination(for: GameDestination.self) { game in
                switch game {
                case .hiddenObject:
                    HiddenObjectGameView()
                case .tattooMistake:
                    TattooMistakeGameView()
                }
            }
    }
}
