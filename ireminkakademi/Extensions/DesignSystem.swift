import SwiftUI

// MARK: - INKAKADEMİ Premium Design System v2
// Centralized tokens for the warm, luxury tattoo-school aesthetic.

// MARK: - Spacing

enum AppSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 40

    /// Standard outer horizontal padding for screens
    static let screenH: CGFloat = 22
    /// Standard vertical gap between major sections
    static let sectionGap: CGFloat = 32
    /// Internal card padding – more generous
    static let cardInner: CGFloat = 24
    /// Hero card internal padding
    static let heroInner: CGFloat = 28
}

// MARK: - Radii

enum AppRadii {
    static let sm:   CGFloat = 12
    static let md:   CGFloat = 16
    static let lg:   CGFloat = 22
    static let xl:   CGFloat = 26
    static let xxl:  CGFloat = 30
    static let pill:  CGFloat = 999
    /// Tab bar outer
    static let tabBar: CGFloat = 32
    /// Card default – larger, softer
    static let card: CGFloat = 24
    /// Hero card
    static let hero: CGFloat = 28
}

// MARK: - Shadows

enum AppShadows {
    static func card(_ scheme: ColorScheme = .light) -> some ShapeStyle {
        Color.black.opacity(scheme == .dark ? 0.32 : 0.06)
    }

    static let cardRadius: CGFloat = 20
    static let cardY: CGFloat = 8

    static let softRadius: CGFloat = 12
    static let softY: CGFloat = 5

    static let elevatedRadius: CGFloat = 28
    static let elevatedY: CGFloat = 14

    static let subtleRadius: CGFloat = 8
    static let subtleY: CGFloat = 3

    /// Shadow opacity that adapts to the current color scheme
    static func opacity(light: Double = 0.06, dark: Double = 0.28) -> Double {
        // Use with @Environment(\.colorScheme) in views
        // Provided as a convenience reference
        light
    }
}

// MARK: - Typography helpers

enum AppFont {
    static func hero(_ size: CGFloat = 30) -> Font { AppTypography.pageTitle(size: size) }
    static func display(_ size: CGFloat = 26) -> Font { AppTypography.sectionHeading(size: size) }
    static func sectionTitle(_ size: CGFloat = 18) -> Font { AppTypography.cardTitle(size: size) }
    static func cardTitle(_ size: CGFloat = 17) -> Font { AppTypography.cardTitle(size: size) }
    static func body(_ size: CGFloat = 15) -> Font { AppTypography.body(size: size) }
    static func caption(_ size: CGFloat = 13) -> Font { AppTypography.caption(size: size) }
    static func micro(_ size: CGFloat = 11) -> Font { AppTypography.navigationLabel(size: size) }
    static func eyebrow(_ size: CGFloat = 11) -> Font { AppTypography.mono(size: size) }
    static func price(_ size: CGFloat = 32) -> Font { AppTypography.displayStat(size: size) }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                    .fill(
                        isDisabled
                            ? AnyShapeStyle(Color.inkTextTertiary)
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.inkAccent, Color.inkAccentDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .shadow(color: isDisabled ? .clear : Color.inkAccent.opacity(0.3), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryPillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.inkTextPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(Color.inkSurfaceSecondary)
            )
            .overlay(
                Capsule()
                    .stroke(Color.inkBorder, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct IconCircleButtonStyle: ButtonStyle {
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Color.inkSurface)
                    .shadow(color: .black.opacity(0.07), radius: 8, y: 3)
            )
            .overlay(
                Circle()
                    .stroke(Color.inkBorder, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct AccentCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.inkAccent, Color.inkAccentDeep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: Color.inkAccent.opacity(0.25), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Reusable Card Modifiers

struct PremiumCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppRadii.card
    var borderColor: Color = .inkBorder
    var borderOpacity: Double = 1.0
    var shadowRadius: CGFloat = AppShadows.cardRadius
    var shadowY: CGFloat = AppShadows.cardY

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.inkSurface)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor.opacity(borderOpacity), lineWidth: colorScheme == .dark ? 0.8 : 0.5)
            )
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.28 : 0.06),
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }
}

extension View {
    func premiumCard(
        cornerRadius: CGFloat = AppRadii.card,
        borderColor: Color = .inkBorder,
        borderOpacity: Double = 1.0
    ) -> some View {
        modifier(PremiumCardModifier(
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            borderOpacity: borderOpacity
        ))
    }
}

// MARK: - Premium Hero Card Modifier

struct PremiumHeroCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppRadii.hero

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.inkSurfaceElevated, Color.inkSurface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.inkAccent.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: AppShadows.elevatedRadius, x: 0, y: AppShadows.elevatedY)
    }
}

extension View {
    func premiumHeroCard(cornerRadius: CGFloat = AppRadii.hero) -> some View {
        modifier(PremiumHeroCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Status Chip

struct StatusChip: View {
    let text: String
    var icon: String? = nil
    var foreground: Color = .inkAccent
    var background: Color = .inkAccentSoft

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(background)
        .clipShape(Capsule())
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let text: String
    var icon: String = "checkmark.circle.fill"
    var iconColor: Color = .inkAccent
    var textColor: Color = .inkTextPrimary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 18, alignment: .center)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
    }
}

// MARK: - Price Block

struct PriceBlock: View {
    let price: String
    var originalPrice: String? = nil
    var badge: String? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let originalPrice {
                    Text(originalPrice)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.inkTextTertiary)
                        .strikethrough(color: Color.inkTextTertiary)
                }
                Text(price)
                    .font(AppFont.price())
                    .foregroundStyle(Color.inkTextPrimary)
            }

            if let badge {
                Text(badge.uppercased(with: Locale(identifier: "tr_TR")))
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.inkAccent, Color.inkAccentDeep],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
    }
}

// MARK: - Section Header (Premium)

struct PremiumSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.sectionTitle())
                    .foregroundStyle(Color.inkTextPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.caption(12))
                        .foregroundStyle(Color.inkTextTertiary)
                }
            }

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(AppFont.caption(13))
                    .foregroundStyle(Color.inkAccent)
            }
        }
    }
}

// MARK: - Animated Card Entrance

struct AnimatedEntrance: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 12)
            .scaleEffect(isVisible ? 1 : 0.98)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

extension View {
    func animatedEntrance(delay: Double = 0) -> some View {
        modifier(AnimatedEntrance(delay: delay))
    }
}