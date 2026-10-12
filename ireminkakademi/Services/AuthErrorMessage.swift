import Foundation

enum AuthErrorMessage {
    static func from(_ error: Error) -> String {
        if let local = error as? LocalAuthError, let message = local.errorDescription {
            return message
        }
        if let api = error as? InkAPIError {
            switch api {
            case .paymentRequired:
                return "Bu içerik için güncel bir abonelik gerekiyor."
            case .server(let message) where message.localizedCaseInsensitiveContains("already registered"):
                return "Bu e-posta ile zaten bir hesap var."
            case .server(let message) where message.localizedCaseInsensitiveContains("username taken"):
                return LocalAuthError.usernameTaken.errorDescription ?? "Bu kullanıcı adı alınmış."
            case .server(let message) where message.localizedCaseInsensitiveContains("invalid or expired"):
                return "Kod geçersiz veya süresi dolmuş."
            case .server(let message) where message.localizedCaseInsensitiveContains("mail delivery failed"):
                return "Onay e-postası şu an gönderilemedi. Birkaç dakika sonra tekrar dene."
            case .server(let message) where message.localizedCaseInsensitiveContains("invalid input"):
                return "Bilgilerini kontrol edip tekrar dene."
            case .server(let message) where message.localizedCaseInsensitiveContains("only jpeg, png or pdf"):
                return "Sadece PNG, JPEG, JPG veya PDF yükleyebilirsin."
            case .server(let message) where message.localizedCaseInsensitiveContains("invalid file"):
                return "Sadece PNG, JPEG, JPG veya PDF yükleyebilirsin."
            case .server(let message) where message.localizedCaseInsensitiveContains("payload too large"):
                return "Dosya en fazla 10 MB olabilir."
            case .server(let message) where message.localizedCaseInsensitiveContains("teslim tarihi"):
                return "Teslim tarihi geçti. Bu ödeve artık yükleme yapılamaz."
            case .server(let message) where message.localizedCaseInsensitiveContains("çok sık") || message.localizedCaseInsensitiveContains("çok hızlı"):
                return message
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
