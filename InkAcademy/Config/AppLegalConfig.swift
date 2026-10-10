import Foundation

/// App Store / yasal metinler ve destek — Info.plist veya build ayarlarından override edilebilir.
enum AppLegalConfig {
    static var privacyPolicyURL: URL {
        url(from: "INK_PRIVACY_POLICY_URL")
            ?? URL(string: "https://inkakademi.com/gizlilik")!
    }

    static var termsOfUseURL: URL {
        url(from: "INK_TERMS_URL")
            ?? URL(string: "https://inkakademi.com/kullanim-kosullari")!
    }

    static var helpCenterURL: URL? {
        url(from: "INK_HELP_CENTER_URL")
    }

    static let supportEmail = "inkakademidestek@outlook.com"

    static var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "Sürüm \(version) (\(build))"
    }

    private static func url(from key: String) -> URL? {
        guard let raw = Bundle.main.infoDictionary?[key] as? String,
              let url = URL(string: raw),
              !raw.isEmpty else { return nil }
        return url
    }
}
