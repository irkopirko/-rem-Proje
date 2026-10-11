import SwiftUI

struct BadgeEarnedPopup: View {
    let badge: BadgeDTO
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 16) {
                BadgeGlyph(badge: badge.asEarnedDisplay, size: 42)
                    .frame(width: 92, height: 92)
                    .glassChrome(radius: 22, emphasized: true)

                Text("Tebrikler")
                    .font(AppTypography.sectionHeading(size: 26))
                    .tracking(AppTypography.tracking(forDisplaySize: 26))
                    .foregroundStyle(InkMockup.textPrimary)

                Text(badge.title)
                    .font(AppTypography.cardTitle(size: 20))
                    .foregroundStyle(InkMockup.textPrimary)
                    .multilineTextAlignment(.center)

                Text(purpose)
                    .font(AppTypography.body(size: 15))
                    .foregroundStyle(InkMockup.captionColor)
                    .multilineTextAlignment(.center)

                Text("+\(badge.xpReward) XP")
                    .font(AppTypography.monoMedium(size: 13))
                    .tracking(1.2)
                    .foregroundStyle(InkMockup.accentPink)

                GlassButton(title: "Harika", action: onDismiss)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .glassChrome(radius: 26, emphasized: true)
            .padding(.horizontal, 36)
        }
        .accessibilityAddTraits(.isModal)
    }

    private var purpose: String {
        let text = badge.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? "Bu rozeti kazandın." : text
    }
}

private extension BadgeDTO {
    var asEarnedDisplay: BadgeDTO {
        var copy = self
        if copy.earnedAt == nil { copy.earnedAt = ISO8601DateFormatter().string(from: Date()) }
        return copy
    }
}
