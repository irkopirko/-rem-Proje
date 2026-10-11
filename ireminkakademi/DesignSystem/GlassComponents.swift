import SwiftUI

enum InkGlass {
    static let background = Color(hex: 0x0B080D)
    static let surface = Color(hex: 0x211820)
    static let burgundy = Color(hex: 0x481B30)
    static let rose = Color(hex: 0xC43B70)
    static let textPrimary = Color(hex: 0xF7F3F6)
    static let textSecondary = Color(hex: 0xADA1AA)
    static let border = Color.white.opacity(0.12)
    static let largeRadius: CGFloat = 24
    static let smallRadius: CGFloat = 16
}

struct GlassBackground: View {
    var body: some View {
        ZStack {
            InkGlass.background
            RadialGradient(
                colors: [InkGlass.burgundy.opacity(0.55), .clear],
                center: UnitPoint(x: 0.18, y: 0.02),
                startRadius: 8,
                endRadius: 420
            )
            RadialGradient(
                colors: [InkGlass.rose.opacity(0.14), .clear],
                center: UnitPoint(x: 0.72, y: 0.08),
                startRadius: 10,
                endRadius: 340
            )
            RadialGradient(
                colors: [InkGlass.rose.opacity(0.10), InkGlass.burgundy.opacity(0.18), .clear],
                center: UnitPoint(x: 0.92, y: 1.05),
                startRadius: 20,
                endRadius: 380
            )
            LinearGradient(
                colors: [
                    InkGlass.surface.opacity(0.28),
                    .clear,
                    InkGlass.burgundy.opacity(0.22),
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

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { glassFill(radius: radius, emphasized: emphasized, reduceTransparency: reduceTransparency) }
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
            .foregroundStyle(InkGlass.textPrimary)
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

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                glassFill(
                    radius: InkGlass.smallRadius,
                    emphasized: emphasized,
                    reduceTransparency: false,
                    pressed: configuration.isPressed
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

    func body(content: Content) -> some View {
        content.background {
            glassFill(radius: radius, emphasized: emphasized, reduceTransparency: reduceTransparency)
        }
    }
}

extension View {
    func glassChrome(radius: CGFloat = InkGlass.largeRadius, emphasized: Bool = false) -> some View {
        modifier(GlassChrome(radius: radius, emphasized: emphasized))
    }
}

@ViewBuilder
func glassFill(radius: CGFloat, emphasized: Bool, reduceTransparency: Bool, pressed: Bool = false) -> some View {
    let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
    ZStack {
        if reduceTransparency {
            shape.fill(InkGlass.surface)
        } else {
            shape.fill(InkGlass.surface.opacity(emphasized ? 0.78 : 0.62))
            if emphasized {
                shape.fill(InkGlass.rose.opacity(pressed ? 0.38 : 0.22))
            }
        }
        shape.fill(
            LinearGradient(
                colors: [
                    Color.white.opacity(pressed ? 0.14 : 0.08),
                    .clear,
                    Color.black.opacity(0.18),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        shape.stroke(
            LinearGradient(
                colors: [
                    Color.white.opacity(pressed || emphasized ? 0.22 : 0.14),
                    Color.white.opacity(0.05),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 0.8
        )
    }
    .shadow(color: Color.black.opacity(0.34), radius: 16, x: 0, y: 8)
    .shadow(color: InkGlass.rose.opacity(emphasized ? 0.14 : 0.06), radius: 18, x: 0, y: 4)
    .clipShape(shape)
}
