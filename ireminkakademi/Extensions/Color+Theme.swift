import SwiftUI
import UIKit

// MARK: - INKAKADEMİ Premium Design Tokens
// Warm cream / off-white palette with a rich multi-accent system.
// Orange = primary CTA · Teal = learning · Indigo = structure · Rose = passion · Sage = success
// Full dark mode support – dark surfaces flip to deep warm charcoal tones.

extension Color {

    // MARK: - Core Surfaces

    /// Warm parchment background – soft gray aligned with page gradient
    static let inkBackground       = Color(light: 0xE8E6EB, dark: 0x0B080D)
    /// Card surface – warm ivory / dark elevated surface
    static let inkSurface          = Color(light: 0xFAF8F3, dark: 0x211820)
    /// Secondary surface – warm beige / dark mid-tone
    static let inkSurfaceSecondary = Color(light: 0xEDE9E0, dark: 0x2A1C26)
    /// Elevated surface – richer warmth / slightly lighter dark
    static let inkSurfaceElevated  = Color(light: 0xFFF9EF, dark: 0x2F2030)
    /// Pure white / near-white in dark mode
    static let inkWhite            = Color(light: 0xFFFFFF, dark: 0xFAF8F3)

    // MARK: - Text

    /// Near-black primary text / off-white in dark mode
    static let inkTextPrimary   = Color(light: 0x1A1612, dark: 0xF7F3F6)
    /// Medium warm-gray secondary text
    static let inkTextSecondary = Color(light: 0x7A7368, dark: 0xADA1AA)
    /// Light tertiary / metadata text
    static let inkTextTertiary  = Color(light: 0xADA598, dark: 0x8A7E86)

    // MARK: - Primary Accent (koyu pembe)

    static let inkAccent        = Color(light: 0x8C2A4E, dark: 0xC43B70)
    static let inkAccentSoft    = Color(light: 0xF4E4EB, dark: 0x481B30)
    static let inkAccentMuted   = Color(light: 0xE4C4D0, dark: 0x3A1824)
    static let inkAccentDeep    = Color(light: 0x6E1F3C, dark: 0x481B30)

    // MARK: - Page Gradient (soft gray)

    static let inkGradientTop    = Color(light: 0xECEAEF, dark: 0x211820)
    static let inkGradientBottom = Color(light: 0xDAD7DF, dark: 0x0B080D)

    // MARK: - Teal Accent (Learning / Ink / Modules)

    /// Deep tattoo-ink teal – knowledge & progress
    static let inkTeal          = Color(light: 0x1B8F84, dark: 0x38B2A8)
    /// Soft teal background tint
    static let inkTealSoft      = Color(light: 0xDFF1EE, dark: 0x162E2B)
    /// Deep teal for gradients
    static let inkTealDeep      = Color(light: 0x147368, dark: 0x2A9A90)

    // MARK: - Indigo Accent (Structure / Assignments / Professional)

    /// Rich slate-indigo – structure & organization
    static let inkIndigo        = Color(light: 0x4A5C8A, dark: 0x7B8DB8)
    /// Soft indigo background tint
    static let inkIndigoSoft    = Color(light: 0xE6EAF2, dark: 0x1C1F2C)
    /// Deep indigo for gradients
    static let inkIndigoDeep    = Color(light: 0x3A4A72, dark: 0x6478A0)

    // MARK: - Rose Accent (Passion / Art / Streaks / Highlights)

    /// Warm muted rose – passion & creativity
    static let inkRose          = Color(light: 0xC4566A, dark: 0xE07080)
    /// Soft rose background tint
    static let inkRoseSoft      = Color(light: 0xF8E8EB, dark: 0x2E181C)
    /// Deep rose for gradients
    static let inkRoseDeep      = Color(light: 0xA84458, dark: 0xC86070)

    // MARK: - Sage Accent (Success / Completion / Earth)

    /// Earthy sage green – natural success state
    static let inkSage          = Color(light: 0x5E9268, dark: 0x7AB085)
    /// Soft sage background tint
    static let inkSageSoft      = Color(light: 0xE4F0E6, dark: 0x1A2C1E)
    /// Deep sage for gradients
    static let inkSageDeep      = Color(light: 0x4A7A54, dark: 0x689E72)

    // MARK: - Legacy aliases (mapped to new values for compile safety)

    static let inkBlack         = Color(light: 0x1A1612, dark: 0xF0ECE4)
    static let inkGold          = Color.inkAccent
    static let inkGoldSoft      = Color.inkAccentSoft
    static let inkGoldMuted     = Color(light: 0xC4A265, dark: 0xD4B275)

    // MARK: - Semantic

    static let inkSuccess       = Color.inkSage
    static let inkWarning       = Color(light: 0xF2A922, dark: 0xF5B838)
    static let inkError         = Color(light: 0xD94040, dark: 0xE85C5C)

    // MARK: - Borders / Dividers

    /// Ultra-subtle warm-gray border
    static let inkBorder        = Color(light: 0xE2DDD3, dark: 0x3A3036)
    /// Softer divider
    static let inkDivider       = Color(light: 0xE8E3D9, dark: 0x2A2228)

    // MARK: - Legacy compile-safety aliases

    static let inkPrimaryFallback     = Color.inkBlack
    static let inkSecondaryFallback   = Color.inkTextSecondary
    static let inkBackgroundFallback  = Color.inkBackground
}

// MARK: - ShapeStyle aliases

extension ShapeStyle where Self == Color {
    static var inkPrimary: Color   { .inkBlack }
    static var inkSecondary: Color { .inkTextSecondary }
}

// MARK: - Hex initializer + Adaptive Color helper

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue:  Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }

    /// Creates an adaptive color that resolves to `light` hex in light mode
    /// and `dark` hex in dark mode.
    init(light: UInt, dark: UInt) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(
                    red: CGFloat((dark >> 16) & 0xFF) / 255.0,
                    green: CGFloat((dark >> 8) & 0xFF) / 255.0,
                    blue: CGFloat(dark & 0xFF) / 255.0,
                    alpha: 1.0
                  )
                : UIColor(
                    red: CGFloat((light >> 16) & 0xFF) / 255.0,
                    green: CGFloat((light >> 8) & 0xFF) / 255.0,
                    blue: CGFloat(light & 0xFF) / 255.0,
                    alpha: 1.0
                  )
        })
    }
}