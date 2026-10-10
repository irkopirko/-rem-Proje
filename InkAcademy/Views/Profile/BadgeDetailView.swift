import SwiftUI

struct BadgeDetailView: View {
    let badge: Badge
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(badge.displayImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .padding(.top, 12)

                    VStack(spacing: 8) {
                        Text(badge.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.inkTextPrimary)

                        Text(badge.isEarned ? "Kazanıldı" : "Henüz kilitli")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(badge.isEarned ? Color.inkAccent : Color.inkTextTertiary)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        detailRow(title: "Açıklama", value: badge.description)
                        detailRow(title: "Kazanma şartı", value: badge.requirementDescription)
                        detailRow(title: "XP ödülü", value: "+\(badge.xpReward) XP")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.lg)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, AppSpacing.screenH)
                .padding(.bottom, AppSpacing.xl)
            }
            .inkPageBackground()
            .navigationTitle("Rozet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.inkTextTertiary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.inkTextPrimary)
        }
    }
}

#Preview {
    BadgeDetailView(badge: Badge.catalog[0])
}
