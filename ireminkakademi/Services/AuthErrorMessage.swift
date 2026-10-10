import Foundation

enum AuthErrorMessage {
    static func from(_ error: Error) -> String {
        if let local = error as? LocalAuthError, let message = local.errorDescription {
            return message
        }
        if let api = error as? InkAPIError {
            switch api {
            case .server(let message) where message.localizedCaseInsensitiveContains("already registered"):
                return "Bu e-posta ile zaten bir hesap var."
            case .server(let message) where message.localizedCaseInsensitiveContains("username taken"):
                return LocalAuthError.usernameTaken.errorDescription ?? "Bu kullanıcı adı alınmış."
            case .server(let message) where message.localizedCaseInsensitiveContains("invalid or expired"):
                return "Kod geçersiz veya süresi dolmuş."
            case .server(let message) where message.localizedCaseInsensitiveContains("invalid input"):
                return "Bilgilerini kontrol edip tekrar dene."
            default:
                return api.errorDescription ?? "Bir hata oluştu."
            }
        }
        if error is URLError {
            return "Sunucuya ulaşılamadı. İnternet bağlantını kontrol edip tekrar dene."
        }
        return "Bir hata oluştu. Lütfen tekrar dene."
    }
}
