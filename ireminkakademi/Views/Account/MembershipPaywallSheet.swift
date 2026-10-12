import SwiftUI

/// Deneme kullanıcısı üyelik-only içeriğe basınca paket seçenekleri.
struct MembershipPaywallSheet: View {
    var onDismiss: () -> Void
    @Environment(\.openURL) private var openURL

    private let packages: [(name: String, detail: String)] = [
        ("Light", "Eğitimler ve ödevler"),
        ("Plus", "Tüm eğitimler, ödevler ve canlı yayınlar"),
        ("Life Plus", "Plus ile aynı erişim, süresiz"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(InkMockup.accentPink)
                Text("Üyelik gerekiyor")
                    .font(AppTypography.sectionHeading(size: 22))
                    .foregroundStyle(InkMockup.textPrimary)
                Spacer()
            }

            Text("Bu içeriği görmek için üyelik alman gerekiyor. Ink Akademi Crew’un yalnızca üyeliğe açtığı dersler ve ödevler deneme sürümünde kilitli görünür.")
                .font(AppTypography.body(size: 15))
                .foregroundStyle(InkMockup.captionColor)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(packages, id: \.name) { pack in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(InkMockup.accentPink)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pack.name)
                                .font(AppTypography.cardTitle(size: 17))
                                .foregroundStyle(InkMockup.textPrimary)
                            Text(pack.detail)
                                .font(AppTypography.caption())
                                .foregroundStyle(InkMockup.captionColor)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .glassChrome(radius: 16)
                }
            }

            Text("Üyelik App Store’dan satılmaz. Ink Akademi kaydınla tanımlanır.")
                .font(AppTypography.caption(size: 12))
                .foregroundStyle(InkMockup.placeholderColor)

            Button {
                if let url = URL(string: "mailto:\(AppLegalConfig.supportEmail)?subject=Üyelik") {
                    openURL(url)
                }
            } label: {
                Text("Üyelik için bize yaz")
                    .font(AppTypography.button())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: InkMockup.buttonHeight)
                    .background {
                        glassFill(radius: InkGlass.smallRadius, emphasized: true, reduceTransparency: false, colorScheme: .dark)
                    }
            }
            .buttonStyle(.plain)

            Button("Kapat", action: onDismiss)
                .font(AppTypography.button(size: 15))
                .foregroundStyle(InkMockup.captionColor)
                .frame(maxWidth: .infinity)
        }
        .padding(22)
        .glassChrome(radius: 26, emphasized: false)
        .padding(.horizontal, 20)
    }
}

struct LockedContentOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
            Image(systemName: "lock.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
        .allowsHitTesting(false)
    }
}
