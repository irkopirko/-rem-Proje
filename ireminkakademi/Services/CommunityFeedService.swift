import Foundation

@Observable
final class CommunityFeedService {
    @ObservationIgnored private let api = InkAPIClient.shared

    func latest() async throws -> FeedPostDTO? {
        let resp: FeedLatestResponse = try await api.request("/v1/feed/latest", authorized: true)
        return resp.post
    }

    func list(cursor: String? = nil) async throws -> FeedListResponse {
        var path = "/v1/feed/posts?limit=20"
        if let cursor, let encoded = cursor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            path += "&cursor=\(encoded)"
        }
        return try await api.request(path, authorized: true)
    }

    func post(id: String) async throws -> FeedPostDTO {
        let resp: FeedPostResponse = try await api.request("/v1/feed/posts/\(id)", authorized: true)
        return resp.post
    }

    func create(body: String, clientRequestId: String) async throws -> FeedPostDTO {
        struct Body: Encodable { let body: String; let clientRequestId: String }
        let resp: FeedPostResponse = try await api.request(
            "/v1/feed/posts",
            method: "POST",
            body: Body(body: body, clientRequestId: clientRequestId),
            authorized: true
        )
        return resp.post
    }

    func uploadMedia(postId: String, data: Data, contentType: String) async throws -> FeedMediaDTO {
        struct Resp: Decodable { let media: FeedMediaDTO }
        let resp: Resp = try await api.upload("/v1/feed/posts/\(postId)/media", data: data, contentType: contentType)
        return resp.media
    }

    func uploadMedia(postId: String, fileURL: URL, contentType: String) async throws -> FeedMediaDTO {
        struct Resp: Decodable { let media: FeedMediaDTO }
        let resp: Resp = try await api.uploadFile("/v1/feed/posts/\(postId)/media", fileURL: fileURL, contentType: contentType)
        return resp.media
    }

    func uploadVideo(postId: String, fileURL: URL, contentType: String, size: Int) async throws -> FeedMediaDTO {
        struct SessionBody: Encodable {
            let mimeType: String
            let size: Int
        }
        struct SessionResp: Decodable { let upload: HomeworkUploadTarget }
        struct Confirm: Encodable {
            let key: String
            let mimeType: String
            let size: Int
        }
        struct Resp: Decodable { let media: FeedMediaDTO }
        do {
            let session: SessionResp = try await api.request(
                "/v1/feed/posts/\(postId)/upload-session",
                method: "POST",
                body: SessionBody(mimeType: contentType, size: size),
                authorized: true
            )
            guard let putURL = URL(string: session.upload.url) else { throw InkAPIError.invalidURL }
            try await api.putFile(to: putURL, fileURL: fileURL, headers: session.upload.headers)
            let resp: Resp = try await api.request(
                "/v1/feed/posts/\(postId)/media",
                method: "POST",
                body: Confirm(key: session.upload.key, mimeType: contentType, size: size),
                authorized: true
            )
            return resp.media
        } catch InkAPIError.server(let message) where message.localizedCaseInsensitiveContains("depolama") {
            guard size <= 8 * 1024 * 1024 else { throw InkAPIError.server(message) }
            return try await uploadMedia(postId: postId, fileURL: fileURL, contentType: contentType)
        }
    }

    func uploadVideoThumbnail(mediaId: String, jpeg: Data) async throws -> FeedMediaDTO {
        struct Resp: Decodable { let media: FeedMediaDTO }
        let resp: Resp = try await api.upload("/v1/feed/media/\(mediaId)/thumbnail", data: jpeg, contentType: "image/jpeg")
        return resp.media
    }

    func deletePost(id: String) async throws {
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await api.request("/v1/feed/posts/\(id)", method: "DELETE", authorized: true)
    }

    func toggleLike(postId: String) async throws -> FeedLikeResponse {
        try await api.request("/v1/feed/posts/\(postId)/like", method: "POST", authorized: true)
    }

    func replies(postId: String) async throws -> [FeedReplyDTO] {
        let resp: FeedRepliesResponse = try await api.request("/v1/feed/posts/\(postId)/replies", authorized: true)
        return resp.replies
    }

    func createReply(postId: String, body: String, parentReplyId: String?, hasMedia: Bool, clientRequestId: String) async throws -> FeedReplyResponse {
        struct Body: Encodable {
            let body: String
            let parentReplyId: String?
            let hasMedia: Bool
            let clientRequestId: String
        }
        return try await api.request(
            "/v1/feed/posts/\(postId)/replies",
            method: "POST",
            body: Body(body: body, parentReplyId: parentReplyId, hasMedia: hasMedia, clientRequestId: clientRequestId),
            authorized: true
        )
    }

    func uploadReplyMedia(replyId: String, data: Data, contentType: String) async throws -> FeedMediaDTO {
        struct Resp: Decodable { let media: FeedMediaDTO }
        let resp: Resp = try await api.upload("/v1/feed/replies/\(replyId)/media", data: data, contentType: contentType)
        return resp.media
    }

    func deleteReply(id: String) async throws {
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await api.request("/v1/feed/replies/\(id)", method: "DELETE", authorized: true)
    }

    func reportPost(id: String) async throws {
        struct Body: Encodable { let reason: String }
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await api.request(
            "/v1/feed/posts/\(id)/report",
            method: "POST",
            body: Body(reason: "Uygunsuz içerik"),
            authorized: true
        )
    }

    func reportReply(id: String) async throws {
        struct Body: Encodable { let reason: String }
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await api.request(
            "/v1/feed/replies/\(id)/report",
            method: "POST",
            body: Body(reason: "Uygunsuz içerik"),
            authorized: true
        )
    }
}
