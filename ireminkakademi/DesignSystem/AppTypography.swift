import SwiftUI
import UIKit

/// Editorial type system for the student studio.
///
/// - Space Grotesk Medium — page titles, section headings, large XP
/// - Neue Montreal — card titles and labels (falls back to Inter until installed)
/// - Inter — body, buttons, navigation
/// - IBM Plex Mono — XP, levels, progress metadata
enum AppTypography {
    static let missingNeueMontrealNote = "Neue Montreal is not bundled (commercial license). Inter is the temporary fallback until NeueMontreal-Regular / NeueMontreal-Medium are added to Resources/Fonts."

    private static var spaceGroteskMedium: String {
        AppFontRegistry.firstAvailable([
            "SpaceGrotesk-Medium",
            "Space Grotesk Medium",
            "Space Grotesk",
        ]) ?? "SpaceGrotesk-Medium"
    }

    private static var neueMontrealRegular: String {
        AppFontRegistry.firstAvailable([
            "NeueMontreal-Regular",
            "PPNeueMontreal-Regular",
            "Neue Montreal",
        ]) ?? interRegular
    }

    private static var neueMontrealMedium: String {
        AppFontRegistry.firstAvailable([
            "NeueMontreal-Medium",
            "PPNeueMontreal-Medium",
            "Neue Montreal Medium",
        ]) ?? interMedium
    }

    private static var interRegular: String {
        AppFontRegistry.firstAvailable(["Inter-Regular", "Inter"]) ?? "Inter-Regular"
    }

    private static var interMedium: String {
        AppFontRegistry.firstAvailable(["Inter-Medium", "Inter Medium"]) ?? "Inter-Medium"
    }

    private static var plexRegular: String {
        AppFontRegistry.firstAvailable(["IBMPlexMono-Regular", "IBM Plex Mono"]) ?? "IBMPlexMono-Regular"
    }

    private static var plexMedium: String {
        AppFontRegistry.firstAvailable(["IBMPlexMono-Medium", "IBM Plex Mono Medium"]) ?? "IBMPlexMono-Medium"
    }

    static var isNeueMontrealInstalled: Bool {
        AppFontRegistry.firstAvailable([
            "NeueMontreal-Regular",
            "NeueMontreal-Medium",
            "PPNeueMontreal-Regular",
            "PPNeueMontreal-Medium",
        ]) != nil
    }

    // MARK: Display — Space Grotesk

    static func pageTitle(size: CGFloat = 34) -> Font {
        custom(spaceGroteskMedium, size: size, relativeTo: .largeTitle)
    }

    static func sectionHeading(size: CGFloat = 26) -> Font {
        custom(spaceGroteskMedium, size: size, relativeTo: .title2)
    }

    static func displayStat(size: CGFloat = 32) -> Font {
        custom(spaceGroteskMedium, size: size, relativeTo: .title)
    }

    // MARK: Secondary — Neue Montreal (Inter fallback)

    static func cardTitle(size: CGFloat = 18) -> Font {
        custom(neueMontrealMedium, size: size, relativeTo: .headline)
    }

    static func subheading(size: CGFloat = 16) -> Font {
        custom(neueMontrealRegular, size: size, relativeTo: .title3)
    }

    static func profileLabel(size: CGFloat = 15) -> Font {
        custom(neueMontrealRegular, size: size, relativeTo: .body)
    }

    // MARK: Body — Inter

    static func body(size: CGFloat = 15) -> Font {
        custom(interRegular, size: size, relativeTo: .body)
    }

    static func button(size: CGFloat = 16) -> Font {
        custom(interMedium, size: size, relativeTo: .body)
    }

    static func navigationLabel(size: CGFloat = 11) -> Font {
        custom(interMedium, size: size, relativeTo: .caption2)
    }

    static func caption(size: CGFloat = 13) -> Font {
        custom(interRegular, size: size, relativeTo: .caption)
    }

    // MARK: Technical — IBM Plex Mono

    static func mono(size: CGFloat = 12) -> Font {
        custom(plexRegular, size: size, relativeTo: .caption)
    }

    static func monoMedium(size: CGFloat = 12) -> Font {
        custom(plexMedium, size: size, relativeTo: .caption)
    }

    static func tracking(forDisplaySize size: CGFloat, uppercase: Bool = false) -> CGFloat {
        if uppercase { return size >= 30 ? 1.2 : 0.8 }
        if size >= 32 { return -0.4 }
        if size >= 24 { return 0.3 }
        return 0.6
    }

    static func turkishUppercased(_ text: String) -> String {
        text.uppercased(with: Locale(identifier: "tr_TR"))
    }

    private static func custom(_ name: String, size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        .custom(name, size: size, relativeTo: style)
    }
}

extension Text {
    func inkPageTitle() -> some View {
        self
            .font(AppTypography.pageTitle())
            .tracking(AppTypography.tracking(forDisplaySize: 34, uppercase: true))
            .foregroundStyle(InkMockup.textPrimary)
    }

    func inkSectionHeading() -> some View {
        self
            .font(AppTypography.sectionHeading())
            .tracking(AppTypography.tracking(forDisplaySize: 26))
            .foregroundStyle(InkMockup.textPrimary)
    }

    func inkCardTitle() -> some View {
        font(AppTypography.cardTitle()).foregroundStyle(InkMockup.textPrimary)
    }

    func inkBody() -> some View {
        font(AppTypography.body()).foregroundStyle(InkMockup.captionColor)
    }

    func inkMono() -> some View {
        self
            .font(AppTypography.mono())
            .tracking(1.1)
            .foregroundStyle(InkMockup.captionColor)
    }
}
