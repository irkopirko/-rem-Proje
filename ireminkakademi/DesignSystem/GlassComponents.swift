import SwiftUI

enum InkGlass {
    static let background = Color(light: 0xF7F4F6, dark: 0x0B080D)
    static let surface = Color(light: 0xFFFFFF, dark: 0x211820)
    static let burgundy = Color(light: 0x8A3A55, dark: 0x481B30)
    static let rose = Color(hex: 0xC43B70)
    static let textPrimary = Color(light: 0x1A1216, dark: 0xF7F3F6)
    static let textSecondary = Color(light: 0x6E6168, dark: 0xADA1AA)
    static let border = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.14)
            : UIColor.black.withAlphaComponent(0.10)
    })
    static let largeRadius: CGFloat = 24
    static let smallRadius: CGFloat = 16
}

struct GlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            InkGlass.background
            RadialGradient(
                colors: [InkGlass.burgundy.opacity(colorScheme == .dark ? 0.55 : 0.12), .clear],
                center: UnitPoint(x: 0.18, y: 0.02),
                startRadius: 8,
                endRadius: 420
            )
            RadialGradient(
                colors: [InkGlass.rose.opacity(colorScheme == .dark ? 0.14 : 0.08), .clear],
                center: UnitPoint(x: 0.72, y: 0.08),
                startRadius: 10,
                endRadius: 340
            )
            RadialGradient(
                colors: [
                    InkGlass.rose.opacity(colorScheme == .dark ? 0.10 : 0.06),
                    InkGlass.burgundy.opacity(colorScheme == .dark ? 0.18 : 0.05),
                    .clear,
                ],
                center: UnitPoint(x: 0.92, y: 1.05),
                startRadius: 20,
                endRadius: 380
            )
            LinearGradient(
                colors: [
                    InkGlass.surface.opacity(colorScheme == .dark ? 0.28 : 0.55),
                    .clear,
                    InkGlass.burgundy.opacity(colorScheme == .dark ? 0.22 : 0.04),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct GlassCard<Content: View>: View {
    var radius: CGFloat = InkGlass.largeRadius
    var padding: CGFloat = 16
    var emphasized = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassChrome(radius: radius, emphasized: emphasized)
    }
}

struct GlassSection<Content: View>: View {
    let title: String
    var uppercase = false
    var spacing: CGFloat = 12
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text(uppercase ? AppTypography.turkishUppercased(title) : title)
                .font(uppercase ? AppTypography.pageTitle() : AppTypography.sectionHeading())
                .tracking(AppTypography.tracking(forDisplaySize: uppercase ? 34 : 24, uppercase: uppercase))
                .foregroundStyle(InkMockup.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

struct GlassButton: View {
    let title: String
    var isLoading = false
    var emphasized = true
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading { ProgressView().tint(InkGlass.textPrimary) }
                Text(title).font(AppTypography.button())
            }
            .foregroundStyle(emphasized ? Color.white : InkMockup.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
        }
        .buttonStyle(GlassButtonStyle(emphasized: emphasized, reduceMotion: reduceMotion))
        .disabled(isLoading)
        .accessibilityAddTraits(.isButton)
    }
}

struct GlassButtonStyle: ButtonStyle {
    var emphasized = true
    var reduceMotion = false
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                glassFill(
                    radius: InkGlass.smallRadius,
                    emphasized: emphasized,
                    reduceTransparency: false,
                    pressed: configuration.isPressed,
                    colorScheme: colorScheme
                )
            }
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.985 : 1))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct GlassChrome: ViewModifier {
    var radius: CGFloat = InkGlass.largeRadius
    var emphasized = false

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if reduceTransparency {
            content.background { glassFill(radius: radius, emphasized: emphasized, reduceTransparency: true, colorScheme: colorScheme) }
        } else if #available(iOS 26.0, *) {
            content
                .glassEffect(emphasized ? .regular.tint(InkGlass.rose.opacity(0.20)) : .clear, in: shape)
                .overlay {
                    shape.stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.55 : 0.80),
                                Color(red: 0.78, green: 0.62, blue: 1.0).opacity(0.28),
                                Color.white.opacity(colorScheme == .dark ? 0.12 : 0.28),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.9
                    )
                }
        } else {
            content.background {
                glassFill(
                    radius: radius,
                    emphasized: emphasized,
                    reduceTransparency: false,
                    colorScheme: colorScheme
                )
            }
        }
    }
}

extension View {
    func glassChrome(radius: CGFloat = InkGlass.largeRadius, emphasized: Bool = false) -> some View {
        modifier(GlassChrome(radius: radius, emphasized: emphasized))
    }
}

@ViewBuilder
func glassFill(
    radius: CGFloat,
    emphasized: Bool,
    reduceTransparency: Bool,
    pressed: Bool = false,
    colorScheme: ColorScheme = .dark
) -> some View {
    let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
    let isDark = colorScheme == .dark
    ZStack {
        if reduceTransparency {
            shape.fill(InkGlass.surface)
        } else {
            shape.fill(.ultraThinMaterial)
            shape.fill(Color.white.opacity(isDark ? (emphasized ? 0.06 : 0.04) : (emphasized ? 0.38 : 0.28)))
            if emphasized {
                shape.fill(InkGlass.rose.opacity(pressed ? 0.28 : (isDark ? 0.14 : 0.10)))
            }
        }
        shape.fill(
            LinearGradient(
                colors: [
                    Color.white.opacity(isDark ? (pressed ? 0.28 : 0.20) : 0.62),
                    Color.white.opacity(isDark ? 0.04 : 0.12),
                    Color(red: 0.72, green: 0.55, blue: 0.98).opacity(isDark ? 0.10 : 0.08),
                    .clear,
                    Color.white.opacity(isDark ? 0.07 : 0.20),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        shape.stroke(
            LinearGradient(
                colors: [
                    Color.white.opacity(isDark ? (pressed || emphasized ? 0.55 : 0.42) : 0.82),
                    Color(red: 0.78, green: 0.62, blue: 1.0).opacity(0.30),
                    Color.white.opacity(isDark ? 0.10 : 0.22),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 0.9
        )
    }
    .shadow(color: Color.white.opacity(isDark ? 0.06 : 0.28), radius: 1, x: 0, y: 0.5)
    .shadow(color: Color.black.opacity(isDark ? 0.28 : 0.08), radius: 16, x: 0, y: 8)
    .clipShape(shape)
}
