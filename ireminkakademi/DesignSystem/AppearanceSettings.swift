import SwiftUI
import UIKit

@Observable
final class AppearanceSettings {
    static let shared = AppearanceSettings()

    private let key = "ink.appearance.isDark"

    var isDark: Bool {
        didSet { UserDefaults.standard.set(isDark, forKey: key) }
    }

    var colorScheme: ColorScheme { isDark ? .dark : .light }

    private init() {
        if UserDefaults.standard.object(forKey: key) == nil {
            isDark = true
        } else {
            isDark = UserDefaults.standard.bool(forKey: key)
        }
    }

    /// `Color(light:dark:)` reads the window trait, not only the SwiftUI environment.
    static func applyWindowInterfaceStyle(_ scheme: ColorScheme) {
        let style: UIUserInterfaceStyle = scheme == .dark ? .dark : .light
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}

enum DailyGameStore {
    private static let key = "ink.game.lastPlayDay"

    static var playedToday: Bool {
        UserDefaults.standard.string(forKey: key) == todayKey
    }

    static func markPlayedToday() {
        UserDefaults.standard.set(todayKey, forKey: key)
    }

    private static var todayKey: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
