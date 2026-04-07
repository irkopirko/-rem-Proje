import SwiftUI

// MARK: - Stat Card (small metric tile) – premium warm design

struct DashboardStatCard: View {
    let title: String
    let value: String
    var icon: String? = nil
    var subtitle: String? = nil
    var accentColor: Color = .inkAccent

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if let icon {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadii.sm, style: .continuous)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
            }

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkTextPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkTextSecondary)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.inkTextTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 120, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous)
                .stroke(Color.inkBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: AppShadows.softRadius, x: 0, y: AppShadows.softY)
    }
}

#Preview {
    HStack(spacing: 12) {
        DashboardStatCard(title: "Tamamlanan", value: "3", icon: "checkmark.circle")
        DashboardStatCard(title: "Bekleyen Ödev", value: "2", icon: "doc.text")
    }
    .padding()
    .background(Color.inkBackground)
}