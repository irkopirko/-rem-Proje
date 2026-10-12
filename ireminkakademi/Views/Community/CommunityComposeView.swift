import AVFoundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CommunityComposeView: View {
    let feed: CommunityFeedService
    var onPublished: (FeedPostDTO) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var attachments: [FeedDraftMedia] = []
    @State private var isPublishing = false
    @State private var progressText: String?
    @State private var errorMessage: String?

    private let maxAttachments = 4

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Ne düşünüyorsun?", text: $text, axis: .vertical)
                        .font(AppTypography.body())
                        .foregroundStyle(InkMockup.textPrimary)
                        .lineLimit(6...12)
                        .padding(16)
                        .glassChrome(radius: 16)

                    if !attachments.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(attachments) { item in
                                    ZStack(alignment: .topTrailing) {
                                        if let image = item.preview {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            InkMockup.cardFill
                                                .overlay {
                                                    Image(systemName: item.isVideo ? "video.fill" : "photo")
                                                        .foregroundStyle(InkMockup.captionColor)
                                                }
                                        }
                                        Button {
                                            attachments.removeAll { $0.id == item.id }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white)
                                                .shadow(radius: 3)
                                        }
                                        .padding(6)
                                    }
                                    .frame(width: 96, height: 96)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }

                    PhotosPicker(
                        selection: $pickerItems,
                        maxSelectionCount: maxAttachments,
                        matching: .any(of: [.images, .videos]),
                        preferredItemEncoding: .compatible
                    ) {
                        Label("Fotoğraf veya video ekle", systemImage: "photo.on.rectangle")
                            .font(AppTypography.button(size: 15))
                            .foregroundStyle(InkMockup.accentPink)
                    }

                    if let progressText {
                        Text(progressText)
                            .font(AppTypography.caption())
                            .foregroundStyle(InkMockup.captionColor)
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.caption())
                            .foregroundStyle(Color.inkError)
                    }
                }
                .padding(InkMockup.screenHorizontal)
            }
            .studentScreenBackground()
            .navigationTitle("Paylaş")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isPublishing {
                        ProgressView()
                    } else {
                        Button("Paylaş") { Task { await publish() } }
                            .fontWeight(.semibold)
                            .disabled(!canPublish)
                    }
                }
            }
            .onChange(of: pickerItems) { _, items in
                Task { await importPicker(items) }
            }
        }
    }

    private var canPublish: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
    }

    private func importPicker(_ items: [PhotosPickerItem]) async {
        var next: [FeedDraftMedia] = []
        var lastError: String?
        for item in items.prefix(maxAttachments) {
            do {
                next.append(try await FeedDraftMedia.load(item))
            } catch {
                lastError = (error as? LocalizedError)?.errorDescription ?? AuthErrorMessage.from(error)
            }
        }
        attachments = next
        errorMessage = next.isEmpty ? lastError : nil
    }

    private func publish() async {
        isPublishing = true
        errorMessage = nil
        defer { isPublishing = false }
        do {
            progressText = "Gönderi hazırlanıyor…"
            let created = try await feed.create(
                body: text.trimmingCharacters(in: .whitespacesAndNewlines),
                clientRequestId: UUID().uuidString.lowercased()
            )
            for (index, item) in attachments.enumerated() {
                progressText = "Medya yükleniyor (\(index + 1)/\(attachments.count))…"
                if let fileURL = item.fileURL {
                    try await feed.uploadMedia(postId: created.id, fileURL: fileURL, contentType: item.contentType)
                } else if let data = item.data {
                    try await feed.uploadMedia(postId: created.id, data: data, contentType: item.contentType)
                }
            }
            let fresh = attachments.isEmpty ? created : (try? await feed.post(id: created.id)) ?? created
            onPublished(fresh)
            dismiss()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
            progressText = nil
        }
    }
}

struct FeedDraftMedia: Identifiable {
    let id = UUID()
    var data: Data? = nil
    var fileURL: URL? = nil
    let contentType: String
    let isVideo: Bool
    let preview: UIImage?

    static func load(_ item: PhotosPickerItem, imagesOnly: Bool = false) async throws -> Self {
        let isMovie = !imagesOnly && item.supportedContentTypes.contains(where: {
            $0.conforms(to: .movie) || $0.conforms(to: .mpeg4Movie) || $0.conforms(to: .quickTimeMovie)
        })
        if isMovie {
            return try await loadVideo(item)
        }
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw InkAPIError.server("Dosya okunamadı")
        }
        guard let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.82) else {
            throw InkAPIError.server("Görsel okunamadı. JPEG veya PNG dene.")
        }
        guard jpeg.count <= 5 * 1024 * 1024 else { throw InkAPIError.server("Görsel en fazla 5 MB olabilir.") }
        return Self(data: jpeg, contentType: "image/jpeg", isVideo: false, preview: image)
    }

    private static func loadVideo(_ item: PhotosPickerItem) async throws -> Self {
        guard let movie = try await item.loadTransferable(type: PickedMovie.self) else {
            throw InkAPIError.server("Video okunamadı.")
        }
        var url = movie.url
        var size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        if size <= 0 { throw InkAPIError.server("Video okunamadı.") }
        if size > 18 * 1024 * 1024 {
            url = try await exportCompressed(url)
            size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        }
        guard size <= 40 * 1024 * 1024 else { throw InkAPIError.server("Video en fazla 40 MB olabilir.") }
        return Self(
            fileURL: url,
            contentType: "video/mp4",
            isVideo: true,
            preview: videoPreview(url: url)
        )
    }

    private static func exportCompressed(_ source: URL) async throws -> URL {
        let asset = AVURLAsset(url: source)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            throw InkAPIError.server("Video hazırlanamadı.")
        }
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent("feed-\(UUID().uuidString).mp4")
        session.outputURL = dest
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = true
        await session.export()
        guard session.status == .completed else {
            throw InkAPIError.server("Video sıkıştırılamadı. Daha kısa bir klip dene.")
        }
        return dest
    }

    private static func videoPreview(url: URL) -> UIImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.2, preferredTimescale: 600)
        guard let cg = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
        return UIImage(cgImage: cg)
    }
}
