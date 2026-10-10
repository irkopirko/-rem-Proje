import SwiftUI

struct LevelCardView: View {
    let level: StudentLevel
    let xpText: String?
    let progress: Double
    let remainingHint: String
    let supplementalHint: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(level.levelColor.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: level.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(level.levelColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Seviye")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.inkTextTertiary)
                    Text(level.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkTextPrimary)
                    if let xpText, !xpText.isEmpty {
                        Text(xpText)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(level.levelColor)
                    }
                }
                Spacer(minLength: 0)
            }

            XPProgressView(progress: progress, tint: level.levelColor)

            Text(remainingHint)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkTextSecondary)

            if let supplementalHint {
                Text(supplementalHint)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.inkAccent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.inkBorder.opacity(0.35), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    LevelCardView(
        level: .tierCirak,
        xpText: "640 XP",
        progress: 0.45,
        remainingHint: "Sonraki seviye için kalan XP: 360",
        supplementalHint: nil
    )
    .padding()
    .background(Color(.systemGray6))
}
