import Foundation

/// Uygulama yalnızca bu HTTPS API'ye bağlanır; veritabanı bilgileri sadece Railway'deki sunucuda durur.
/// Test için Xcode scheme ortam değişkeni `INK_API_BASE_URL` ile başka bir sunucu verilebilir.
enum APIConfiguration {
    static let productionURLString = "https://ink-akademi-api-production.up.railway.app"

    private static var configuredURLString: String? {
        if let env = ProcessInfo.processInfo.environment["INK_API_BASE_URL"], !env.isEmpty {
            return env
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "INK_API_BASE_URL") as? String, !plist.isEmpty {
            return plist
        }
        return productionURLString
    }

    static var isConfigured: Bool {
        guard let value = configuredURLString, let url = URL(string: value) else { return false }
        return url.host != nil
    }

    static var baseURL: URL {
        if let value = configuredURLString, let url = URL(string: value) {
            return url
        }
        return URL(string: "https://localhost:8080")!
    }

    static var usesMockBackend: Bool {
        ProcessInfo.processInfo.environment["INK_USE_MOCK"] == "1"
    }

    /// Sunucu adresi girilmemiş Debug derlemelerinde kayıt/giriş cihazda çalışır.
    static var usesLocalAuth: Bool {
        #if DEBUG
        return !isConfigured
        #else
        return false
        #endif
    }
}
