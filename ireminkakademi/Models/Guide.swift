import Foundation

struct GuideDTO: Decodable {
    var available: Bool? = nil
    var pdfUrl: String? = nil
    var storageConfigured: Bool? = nil
    var maxBytes: Int? = nil

    var fileURL: URL? { pdfUrl.flatMap(URL.init(string:)) }
}

struct GuideUploadTarget: Decodable {
    let url: String
    let method: String
    let headers: [String: String]
    let key: String
    let maxBytes: Int
}

struct GuideUploadSession: Decodable {
    let upload: GuideUploadTarget
}
