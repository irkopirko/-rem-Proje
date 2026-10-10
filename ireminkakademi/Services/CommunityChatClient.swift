import Foundation

struct CommunityMessage: Identifiable, Decodable, Equatable {
    let id: String
    let userId: String
    let username: String?
    let displayName: String
    let role: String
    var photoUrl: String?
    var frame: String? = nil
    let body: String
    let createdAt: String

    var isStaff: Bool { role == "crew" || role == "super_admin" }
    var avatarFrame: AvatarFrame { frame.flatMap(AvatarFrame.init(rawValue:)) ?? (isStaff ? .purple : .gray) }
    var photoURL: URL? { MediaURL.resolve(photoUrl) }
    var initials: String {
        String(displayName.drop { $0 == "@" }.prefix(1)).uppercased(with: Locale(identifier: "tr_TR"))
    }
    var date: Date? { HomeworkDateFormat.parse(createdAt) }
}

/// Henüz sunucu onayı gelmemiş, gönderilmekte olan mesaj.
struct PendingCommunityMessage: Identifiable, Equatable {
    let id: String
    let body: String
    var failed = false
}

struct CommunityReport: Identifiable, Decodable {
    let id: String
    let reason: String?
    let createdAt: String
    let messageId: String
    let body: String
    let messageDeleted: Bool
    let authorId: String
    let authorUsername: String?
    let authorFirstName: String
    let authorBanned: Bool
    let reporterUsername: String?
    let reportCount: Int
}

@Observable
final class CommunityChatClient {
    enum ConnectionState: Equatable {
        case idle
        case connecting
        case online
        case offline
        /// Üyelik yok veya hesap erişimi kapalı.
        case forbidden
    }

    private(set) var state: ConnectionState = .idle
    private(set) var messages: [CommunityMessage] = []
    private(set) var pending: [PendingCommunityMessage] = []
    private(set) var hasMore = true
    private(set) var isLoadingOlder = false
    private(set) var canSend = true
    private(set) var blockedUserIds: Set<String> = []
    private(set) var maxLength = 2000
    var notice: String?

    @ObservationIgnored private let api = InkAPIClient.shared
    @ObservationIgnored private let session = URLSession(configuration: .default)
    @ObservationIgnored private var socket: URLSessionWebSocketTask?
    @ObservationIgnored private var receiveTask: Task<Void, Never>?
    @ObservationIgnored private var pingTask: Task<Void, Never>?
    @ObservationIgnored private var reconnectTask: Task<Void, Never>?
    @ObservationIgnored private var reconnectAttempt = 0
    @ObservationIgnored private var wantsConnection = false
    @ObservationIgnored private var didRetryAuth = false

    private static let pageSize = 50
    private static let historyLimit = 600

    // MARK: Bağlantı

    func connect() {
        guard !wantsConnection else { return }
        wantsConnection = true
        reconnectAttempt = 0
        Task { await open() }
    }

    func disconnect() {
        wantsConnection = false
        reconnectTask?.cancel()
        teardownSocket()
        if state != .forbidden { state = .idle }
    }

    private func open() async {
        guard wantsConnection else { return }
        teardownSocket()
        state = .connecting
        do {
            try await refreshLatest()
            let token = try await api.validAccessToken()
            guard wantsConnection, let url = Self.socketURL else { return }
            let task = session.webSocketTask(with: url)
            task.maximumMessageSize = 64 * 1024
            socket = task
            task.resume()
            try await sendJSON(["type": "auth", "token": token])
            receiveTask = Task { [weak self] in await self?.receiveLoop(task) }
            pingTask = Task { [weak self] in await self?.pingLoop(task) }
        } catch InkAPIError.paymentRequired {
            state = .forbidden
            wantsConnection = false
        } catch InkAPIError.unauthorized {
            state = .offline
            wantsConnection = false
        } catch {
            scheduleReconnect()
        }
    }

    private func teardownSocket() {
        receiveTask?.cancel()
        pingTask?.cancel()
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
    }

    private func scheduleReconnect() {
        teardownSocket()
        guard wantsConnection else { return }
        state = .offline
        reconnectAttempt += 1
        let delay = min(30.0, pow(2.0, Double(min(reconnectAttempt, 5)))) + Double.random(in: 0...1)
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await self?.open()
        }
    }

    private func receiveLoop(_ task: URLSessionWebSocketTask) async {
        while !Task.isCancelled {
            do {
                let message = try await task.receive()
                let data: Data? = switch message {
                case .string(let text): Data(text.utf8)
                case .data(let data): data
                @unknown default: nil
                }
                if let data { handle(data) }
            } catch {
                guard !Task.isCancelled, task === socket else { return }
                await handleClose(code: task.closeCode)
                return
            }
        }
    }

    private func pingLoop(_ task: URLSessionWebSocketTask) async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(25))
            guard !Task.isCancelled else { return }
            task.sendPing { _ in }
        }
    }

    private func handleClose(code: URLSessionWebSocketTask.CloseCode) async {
        switch code.rawValue {
        case 4001 where !didRetryAuth:
            didRetryAuth = true
            _ = try? await api.refreshAccessToken()
            scheduleReconnect()
        case 4003:
            teardownSocket()
            wantsConnection = false
            state = .forbidden
        default:
            scheduleReconnect()
        }
    }

    // MARK: Gelen olaylar

    private struct Envelope: Decodable {
        let type: String
        let message: CommunityMessage?
        let clientMessageId: String?
        let id: String?
        let userId: String?
        let photoUrl: String?
        let code: String?
        let canSend: Bool?
        let blockedUserIds: [String]?
        let maxLength: Int?
    }

    private func handle(_ data: Data) {
        guard let event = try? JSONDecoder().decode(Envelope.self, from: data) else { return }
        switch event.type {
        case "ready":
            state = .online
            reconnectAttempt = 0
            didRetryAuth = false
            canSend = event.canSend ?? true
            blockedUserIds = Set(event.blockedUserIds ?? [])
            maxLength = event.maxLength ?? maxLength
            messages.removeAll { blockedUserIds.contains($0.userId) }
            resendPending()
        case "message":
            if let clientId = event.clientMessageId { pending.removeAll { $0.id == clientId } }
            if let message = event.message { insert([message]) }
        case "deleted":
            if let id = event.id { messages.removeAll { $0.id == id } }
        case "profile":
            guard let userId = event.userId else { return }
            for index in messages.indices where messages[index].userId == userId {
                messages[index].photoUrl = event.photoUrl
            }
        case "banned":
            canSend = false
        case "unbanned":
            canSend = true
        case "error":
            if let clientId = event.clientMessageId, let index = pending.firstIndex(where: { $0.id == clientId }) {
                pending[index].failed = true
            }
            switch event.code {
            case "rate_limited": notice = "Çok hızlı mesaj gönderiyorsun, birkaç saniye bekle."
            case "banned":
                canSend = false
                notice = "Sohbete mesaj gönderme iznin kaldırıldı."
            case "invalid": notice = "Mesaj gönderilemedi (en fazla \(maxLength) karakter)."
            default: notice = "Mesaj gönderilemedi."
            }
        default:
            break
        }
    }

    private func insert(_ incoming: [CommunityMessage]) {
        let known = Set(messages.map(\.id))
        let fresh = incoming.filter { !known.contains($0.id) && !blockedUserIds.contains($0.userId) }
        guard !fresh.isEmpty else { return }
        messages.append(contentsOf: fresh)
        messages.sort { (Int64($0.id) ?? 0) < (Int64($1.id) ?? 0) }
        if messages.count > Self.historyLimit {
            messages.removeFirst(messages.count - Self.historyLimit)
            hasMore = true
        }
    }

    // MARK: Geçmiş

    private struct HistoryResponse: Decodable {
        let messages: [CommunityMessage]
        let hasMore: Bool
    }

    /// Son mesajları çeker; yeniden bağlanınca aradaki mesajları tamamlar.
    private func refreshLatest() async throws {
        let resp: HistoryResponse = try await api.request("/v1/community/messages?limit=\(Self.pageSize)", authorized: true)
        if messages.isEmpty { hasMore = resp.hasMore }
        insert(resp.messages)
    }

    func loadOlder() async {
        guard hasMore, !isLoadingOlder, let first = messages.first else { return }
        isLoadingOlder = true
        defer { isLoadingOlder = false }
        do {
            let resp: HistoryResponse = try await api.request(
                "/v1/community/messages?before=\(first.id)&limit=\(Self.pageSize)",
                authorized: true
            )
            hasMore = resp.hasMore
            let known = Set(messages.map(\.id))
            messages.insert(contentsOf: resp.messages.filter { !known.contains($0.id) }, at: 0)
        } catch {
            notice = AuthErrorMessage.from(error)
        }
    }

    // MARK: Gönderme ve moderasyon

    func send(_ text: String) {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, body.count <= maxLength else { return }
        let message = PendingCommunityMessage(id: UUID().uuidString, body: body)
        pending.append(message)
        transmit(message)
    }

    func retry(_ message: PendingCommunityMessage) {
        guard let index = pending.firstIndex(where: { $0.id == message.id }) else { return }
        pending[index].failed = false
        transmit(pending[index])
    }

    func discard(_ message: PendingCommunityMessage) {
        pending.removeAll { $0.id == message.id }
    }

    private func transmit(_ message: PendingCommunityMessage) {
        guard state == .online else { return }
        Task {
            do {
                try await sendJSON(["type": "send", "body": message.body, "clientMessageId": message.id])
            } catch {
                if let index = pending.firstIndex(where: { $0.id == message.id }) { pending[index].failed = true }
            }
        }
    }

    private func resendPending() {
        for message in pending where !message.failed { transmit(message) }
    }

    private func sendJSON(_ payload: [String: String]) async throws {
        guard let socket else { throw URLError(.notConnectedToInternet) }
        let data = try JSONSerialization.data(withJSONObject: payload)
        try await socket.send(.string(String(decoding: data, as: UTF8.self)))
    }

    private struct OK: Decodable { let ok: Bool }

    func delete(_ message: CommunityMessage) async {
        do {
            let _: OK = try await api.request("/v1/community/messages/\(message.id)", method: "DELETE", authorized: true)
            messages.removeAll { $0.id == message.id }
        } catch {
            notice = AuthErrorMessage.from(error)
        }
    }

    func report(_ message: CommunityMessage, reason: String?) async {
        struct Body: Encodable { let reason: String? }
        do {
            let _: OK = try await api.request(
                "/v1/community/messages/\(message.id)/report",
                method: "POST",
                body: Body(reason: reason),
                authorized: true
            )
            notice = "Bildirimin alındı. Ink Akademi Crew en kısa sürede inceleyecek."
        } catch {
            notice = AuthErrorMessage.from(error)
        }
    }

    func block(userId: String) async {
        do {
            let _: OK = try await api.request("/v1/community/blocks/\(userId)", method: "POST", authorized: true)
            blockedUserIds.insert(userId)
            messages.removeAll { $0.userId == userId }
            notice = "Kullanıcı engellendi. Mesajlarını artık görmeyeceksin."
        } catch {
            notice = AuthErrorMessage.from(error)
        }
    }

    private static var socketURL: URL? {
        guard var components = URLComponents(url: APIConfiguration.baseURL, resolvingAgainstBaseURL: false) else { return nil }
        components.scheme = components.scheme == "http" ? "ws" : "wss"
        components.path = "/ws/community"
        return components.url
    }
}

/// Crew moderasyon uç noktaları.
struct CommunityModerationService {
    private let api = InkAPIClient.shared
    private struct OK: Decodable { let ok: Bool }

    func fetchReports() async throws -> [CommunityReport] {
        struct Resp: Decodable { let reports: [CommunityReport] }
        let resp: Resp = try await api.request("/v1/community/reports", authorized: true)
        return resp.reports
    }

    func resolve(reportId: String) async throws {
        let _: OK = try await api.request("/v1/community/reports/\(reportId)/resolve", method: "POST", authorized: true)
    }

    func deleteMessage(id: String) async throws {
        let _: OK = try await api.request("/v1/community/messages/\(id)", method: "DELETE", authorized: true)
    }

    func setBan(userId: String, banned: Bool) async throws {
        struct Body: Encodable { let banned: Bool }
        let _: OK = try await api.request("/v1/community/ban/\(userId)", method: "POST", body: Body(banned: banned), authorized: true)
    }
}
