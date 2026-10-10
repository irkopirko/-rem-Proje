import Foundation

enum AppLegalConfig {
    static let privacyPolicyURL = URL(string: "https://inkakademionline.com/gizlilik")!
    static let termsOfUseURL = URL(string: "https://inkakademionline.com/kosullar")!
    static let helpCenterURL: URL? = nil
    static let supportEmail = "inkakademidestek@outlook.com"

    static var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Ink Akademi v\(version) (\(build))"
    }
}
