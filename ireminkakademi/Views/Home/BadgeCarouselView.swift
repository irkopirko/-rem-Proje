import SwiftUI

struct BadgeCarouselView: View {
    let badges: [BadgeDTO]
    var onSelect: (BadgeDTO) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(badges) { badge in
                    Button { onSelect(badge) } label: {
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.clear)
                                .frame(width: 92, height: 92)
                                .overlay { BadgeGlyph(badge: badge, size: 30) }
                                .glassChrome(radius: 18)
                            Text(badge.title)
                                .font(AppTypography.caption(size: 12))
                                .foregroundStyle(InkMockup.captionColor)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)
                                .multilineTextAlignment(.center)
                                .frame(width: 92, height: 36, alignment: .top)
                                .padding(.top, 8)
                        }
                        .frame(width: 92, height: 136, alignment: .top)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(badge.title), \(badge.xpReward) XP\(badge.isEarned ? ", kazanıldı" : "")")
                }
            }
            .frame(height: 136, alignment: .top)
        }
    }
}

struct BadgeInfoPopup: View {
    let badge: BadgeDTO
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 14) {
                BadgeGlyph(badge: badge, size: 34)
                    .frame(width: 72, height: 72)
                    .glassChrome(radius: 16)

                Text(badge.title)
                    .font(AppTypography.cardTitle())
                    .foregroundStyle(InkMockup.textPrimary)
                    .multilineTextAlignment(.center)

                Text(howToEarn)
                    .font(AppTypography.body(size: 14))
                    .foregroundStyle(InkMockup.captionColor)
                    .multilineTextAlignment(.center)

                Text("+\(badge.xpReward) XP · \(badge.isEarned ? "Kazanıldı" : "Henüz kazanılmadı")")
                    .font(AppTypography.monoMedium(size: 12))
                    .tracking(1.1)
                    .foregroundStyle(InkMockup.accentPink)

                GlassButton(title: "Tamam", action: onDismiss)
            }
            .padding(22)
            .frame(maxWidth: 320)
            .glassChrome(radius: 24, emphasized: true)
            .padding(.horizontal, 36)
        }
    }

    private var howToEarn: String {
        let text = badge.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? "Bu rozeti tamamlayınca kazanırsın." : text
    }
}

struct BadgeGlyph: View {
    let badge: BadgeDTO
    var size: CGFloat = 30

    var body: some View {
        if let url = badge.imageURL {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit().padding(8)
            } placeholder: {
                fallback
            }
        } else if let name = badge.localImageName {
            Image(name).resizable().renderingMode(.original).scaledToFit().padding(6)
        } else {
            fallback
        }
    }

    private var fallback: some View {
        Image(systemName: badge.symbolName)
            .font(.system(size: size))
            .foregroundStyle(badge.isEarned ? InkMockup.accentPink : InkMockup.placeholderColor)
    }
}
