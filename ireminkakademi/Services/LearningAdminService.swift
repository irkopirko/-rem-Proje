import Foundation

/// Crew: modül ve video yönetimi (`/v1/crew/modules`, `/v1/crew/videos`).
struct LearningAdminService {
    private let api = InkAPIClient.shared

    private struct OK: Decodable { let ok: Bool }
    private struct VideoResp: Decodable { let video: VideoDTO }
    private struct CreatedVideo: Decodable { let video: VideoDTO; let upload: VideoUploadCredentials }
    private struct Credentials: Decodable { let upload: VideoUploadCredentials }

    private struct ModuleBody: Encodable { let title: String; let description: String; let isPublished: Bool }
    private struct VideoBody: Encodable { let title: String; let description: String; let isPublished: Bool }

    func fetchModules() async throws -> CrewModulesResponse {
        try await api.request("/v1/crew/modules", authorized: true)
    }

    func createModule(_ draft: ModuleDraft) async throws -> ModuleDTO {
        struct Resp: Decodable { let module: ModuleDTO }
        let resp: Resp = try await api.request(
            "/v1/crew/modules",
            method: "POST",
            body: ModuleBody(title: draft.title, description: draft.description, isPublished: draft.isPublished),
            authorized: true
        )
        return resp.module
    }

    func updateModule(id: String, _ draft: ModuleDraft) async throws {
        let _: OK = try await api.request(
            "/v1/crew/modules/\(id)",
            method: "PATCH",
            body: ModuleBody(title: draft.title, description: draft.description, isPublished: draft.isPublished),
            authorized: true
        )
    }

    func deleteModule(id: String) async throws {
        let _: OK = try await api.request("/v1/crew/modules/\(id)", method: "DELETE", authorized: true)
    }

    func fetchVideos(moduleId: String) async throws -> [VideoDTO] {
        let resp: ModuleVideosResponse = try await api.request("/v1/crew/modules/\(moduleId)/videos", authorized: true)
        return resp.videos
    }

    func createVideo(moduleId: String, _ draft: VideoDraft) async throws -> (VideoDTO, VideoUploadCredentials) {
        let resp: CreatedVideo = try await api.request(
            "/v1/crew/modules/\(moduleId)/videos",
            method: "POST",
            body: VideoBody(title: draft.title, description: draft.description, isPublished: draft.isPublished),
            authorized: true
        )
        return (resp.video, resp.upload)
    }

    func uploadCredentials(videoId: String) async throws -> VideoUploadCredentials {
        let resp: Credentials = try await api.request("/v1/crew/videos/\(videoId)/upload-credentials", method: "POST", authorized: true)
        return resp.upload
    }

    func markUploaded(videoId: String) async throws {
        let _: VideoResp = try await api.request("/v1/crew/videos/\(videoId)/uploaded", method: "POST", authorized: true)
    }

    func fetchVideo(id: String) async throws -> VideoDTO {
        let resp: VideoResp = try await api.request("/v1/crew/videos/\(id)", authorized: true)
        return resp.video
    }

    func updateVideo(id: String, _ draft: VideoDraft) async throws {
        let _: OK = try await api.request(
            "/v1/crew/videos/\(id)",
            method: "PATCH",
            body: VideoBody(title: draft.title, description: draft.description, isPublished: draft.isPublished),
            authorized: true
        )
    }

    func deleteVideo(id: String) async throws {
        let _: OK = try await api.request("/v1/crew/videos/\(id)", method: "DELETE", authorized: true)
    }
}
