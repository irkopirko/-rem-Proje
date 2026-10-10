import SwiftUI

struct BadgeCardView: View {
    private let cardWidth: CGFloat = 120
    private let cardHeight: CGFloat = 156
    private let imageSize: CGFloat = 80

    let badge: Badge
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 8) {
                Image(badge.displayImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize, height: imageSize)
                    .opacity(badge.isEarned ? 1 : 0.85)

                Text(badge.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.inkTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: cardWidth - 16, height: 32, alignment: .top)

                Text(badge.isEarned ? "+\(badge.xpReward) XP" : "Kilitli")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(badge.isEarned ? Color.inkAccent : Color.inkTextTertiary)
                    .frame(height: 14)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(width: cardWidth, height: cardHeight, alignment: .top)
            .background(Color.inkSurface.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.inkBorder.opacity(badge.isEarned ? 0.45 : 0.25), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
            BadgeCardView(badge: Badge.catalog[0])
            BadgeCardView(badge: Badge.catalog[1])
        }
        .padding()
    }
    .inkPageBackground()
}
