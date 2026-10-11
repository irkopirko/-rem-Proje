import Foundation

enum InkAPIError: LocalizedError {
    case invalidURL
    case unauthorized
    case paymentRequired
    case server(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz sunucu adresi"
        case .unauthorized: return "Oturum süresi doldu"
        case .paymentRequired: return "Bu içerik için aktif üyelik gerekiyor"
        case .server(let msg): return msg
        case .decoding: return "Sunucu yanıtı okunamadı"
        }
    }
}

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String?
    let user: User
}

extension Notification.Name {
    /// Yenileme anahtarı geçersizleşti; kullanıcı yeniden giriş yapmalı.
    static let inkSessionExpired = Notification.Name("inkSessionExpired")
}

/// Aynı anda gelen yenileme isteklerini tek bir ağ çağrısında birleştirir.
@MainActor
private final class TokenRefresher {
    private var inFlight: Task<String, Error>?

    func refresh(using perform: @escaping () async throws -> String) async throws -> String {
        if let inFlight { return try await inFlight.value }
        let task = Task { try await perform() }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }
}

@Observable
final class InkAPIClient {
    static let shared = InkAPIClient()

    @ObservationIgnored private let session: URLSession
    @ObservationIgnored private let decoder: JSONDecoder
    @ObservationIgnored private let encoder = JSONEncoder()
    @ObservationIgnored private let refresher = TokenRefresher()

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Encodable? = nil,
        authorized: Bool = false
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: APIConfiguration.baseURL) else { throw InkAPIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }
        return try await send(req, authorized: authorized) { try await self.session.data(for: $0) }
    }

    /// Ham dosya gövdesi yükler (ör. ürün görseli).
    func upload<T: Decodable>(_ path: String, method: String = "POST", data: Data, contentType: String) async throws -> T {
        guard let url = URL(string: path, relativeTo: APIConfiguration.baseURL) else { throw InkAPIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        return try await send(req, authorized: true) { try await self.session.upload(for: $0, from: data) }
    }

    /// Büyük dosyayı diskten doğrudan hedef adrese yollar (Railway üzerinden geçmez).
    func putFile(to url: URL, fileURL: URL, headers: [String: String]) async throws {
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.timeoutInterval = 60 * 45
        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 60 * 45
        let longSession = URLSession(configuration: config)
        let (_, response) = try await longSession.upload(for: req, fromFile: fileURL)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw InkAPIError.server("Yükleme başarısız (\(status))")
        }
    }

    /// Süresi dolmak üzereyse önce yenilenen, geçerli erişim anahtarı.
    func validAccessToken() async throws -> String {
        guard let token = KeychainTokenStore.accessToken() else { throw InkAPIError.unauthorized }
        if let exp = Self.expiry(of: token), exp.timeIntervalSinceNow > 60 { return token }
        return try await refreshAccessToken()
    }

    func refreshAccessToken() async throws -> String {
        try await refresher.refresh { [session, decoder, encoder] () async throws -> String in
            guard let refresh = KeychainTokenStore.refreshToken(), !refresh.isEmpty else {
                Self.expireSession()
                throw InkAPIError.unauthorized
            }
            struct Body: Encodable { let refreshToken: String }
            struct Resp: Decodable { let accessToken: String; let refreshToken: String }
            var req = URLRequest(url: APIConfiguration.baseURL.appendingPathComponent("auth/refresh"))
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(Body(refreshToken: refresh))
            let (data, response) = try await session.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status == 401 || status == 400 {
                Self.expireSession()
                throw InkAPIError.unauthorized
            }
            guard (200..<300).contains(status), let resp = try? decoder.decode(Resp.self, from: data) else {
                throw InkAPIError.server("Sunucu hatası (\(status))")
            }
            KeychainTokenStore.save(access: resp.accessToken, refresh: resp.refreshToken)
            return resp.accessToken
        }
    }

    private func send<T: Decodable>(
        _ request: URLRequest,
        authorized: Bool,
        transport: (URLRequest) async throws -> (Data, URLResponse)
    ) async throws -> T {
        var req = request
        if authorized {
            req.setValue("Bearer \(try await validAccessToken())", forHTTPHeaderField: "Authorization")
        }
        var (data, response) = try await transport(req)
        guard var http = response as? HTTPURLResponse else { throw InkAPIError.decoding }

        if http.statusCode == 401, authorized {
            req.setValue("Bearer \(try await refreshAccessToken())", forHTTPHeaderField: "Authorization")
            (data, response) = try await transport(req)
            guard let retried = response as? HTTPURLResponse else { throw InkAPIError.decoding }
            http = retried
        }

        switch http.statusCode {
        case 200..<300:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw InkAPIError.decoding
            }
        case 401:
            throw InkAPIError.unauthorized
        case 402:
            throw InkAPIError.paymentRequired
        default:
            if let err = try? decoder.decode(ServerErrorBody.self, from: data) {
                throw InkAPIError.server(err.error)
            }
            throw InkAPIError.server("Sunucu hatası (\(http.statusCode))")
        }
    }

    private static func expireSession() {
        KeychainTokenStore.clear()
        NotificationCenter.default.post(name: .inkSessionExpired, object: nil)
    }

    /// JWT `exp` alanı; imza doğrulaması sunucuda yapılır, burada yalnızca zamanlama için okunur.
    private static func expiry(of jwt: String) -> Date? {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var b64 = parts[1].replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        b64 += String(repeating: "=", count: (4 - b64.count % 4) % 4)
        guard let data = Data(base64Encoded: b64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? Double else { return nil }
        return Date(timeIntervalSince1970: exp)
    }
}

private struct ServerErrorBody: Decodable { let error: String }

private struct AnyEncodable: Encodable {
    let value: Encodable
    init(_ value: Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}
