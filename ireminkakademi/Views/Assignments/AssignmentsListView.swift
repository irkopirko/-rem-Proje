import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct AssignmentsListView: View {
    let container: DIContainer
    @State private var catalog = CatalogService()
    @State private var items: [HomeworkAssignmentDTO] = []

    private var incomplete: [HomeworkAssignmentDTO] {
        items.filter { $0.status == "pending" || $0.status == "graded_revise" }
    }

    private var awaitingReview: [HomeworkAssignmentDTO] {
        items.filter { $0.status == "submitted" || $0.status == "grading" }
    }

    private var completed: [HomeworkAssignmentDTO] {
        items.filter { $0.status == "graded_pass" }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    InkMockSectionTitle(text: "Ödevler")

                    if items.isEmpty {
                        InkMockCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gösterilecek ödev yok")
                                    .font(AppTypography.cardTitle())
                                    .foregroundStyle(InkMockup.textPrimary)
                                Text("Crew senin üyelik sürümüne açık bir ödev yayınladığında burada görünür.")
                                    .font(AppTypography.body(size: 14))
                                    .foregroundStyle(InkMockup.captionColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                        }
                    } else {
                        sectionHeader("Tamamlanmamış Ödevler")
                        homeworkSection(incomplete)

                        sectionHeader("Değerlendirilmeyi Bekleyen Ödevler")
                        homeworkSection(awaitingReview, showStatus: true)

                        sectionHeader("Tamamlanmış Ödevler")
                        homeworkSection(completed, showStatus: true)
                    }
                }
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .studentScreenBackground()
            .navigationBarHidden(true)
            .task {
                items = (try? await catalog.fetchHomework()) ?? []
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.subheading(size: 16))
            .foregroundStyle(InkMockup.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func homeworkSection(_ list: [HomeworkAssignmentDTO], showStatus: Bool = false) -> some View {
        if list.isEmpty {
            InkMockSubheading(text: "—")
        } else {
            VStack(spacing: 10) {
                ForEach(list) { item in
                    NavigationLink {
                        HomeworkDetailView(item: item, catalog: catalog) {
                            items = (try? await catalog.fetchHomework()) ?? items
                        }
                    } label: {
                        InkMockHomeworkPill(
                            title: item.title,
                            subtitle: showStatus ? statusLabel(item) : nil
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func statusLabel(_ item: HomeworkAssignmentDTO) -> String {
        switch item.status {
        case "submitted", "grading": return "Değerlendirme aşamasında."
        case "graded_pass": return "Değerlendirildi."
        case "graded_revise": return "Revize isteniyor."
        default: return ""
        }
    }
}

struct HomeworkDetailView: View {
    let item: HomeworkAssignmentDTO
    let catalog: CatalogService
    var onSubmitted: (() async -> Void)? = nil

    @State private var picked: HomeworkPickedFile?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showFileImporter = false
    @State private var showSourcePicker = false
    @State private var showPhotosPicker = false
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var submitted = false

    private var canUpload: Bool {
        item.status == "pending" || item.status == "graded_revise"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(item.title)
                    .font(AppTypography.sectionHeading())
                    .foregroundStyle(InkMockup.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let due = HomeworkDateFormat.display(item.dueAt) {
                    Label("Son teslim: \(due)", systemImage: "calendar")
                        .font(AppTypography.mono(size: 12))
                        .foregroundStyle(InkMockup.captionColor)
                }

                if !item.gallery.isEmpty {
                    ProductGalleryView(images: item.gallery, height: 260)
                }

                Text(item.explanation)
                    .font(AppTypography.body())
                    .foregroundStyle(InkMockup.captionColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                if submitted || item.status == "submitted" || item.status == "grading" {
                    Text("Ödeviniz gönderildi. Değerlendiriyoruz.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.inkWarning)
                }

                if let score = item.latestScore {
                    Text("Not: \(score)")
                        .font(.headline)
                }

                if canUpload && !submitted {
                    Button { showSourcePicker = true } label: {
                        VStack(spacing: 8) {
                            Text("Dosya")
                                .font(AppTypography.cardTitle(size: 17))
                                .foregroundStyle(InkMockup.textPrimary)
                            Text(picked?.name ?? "PNG, JPEG, JPG, PDF")
                                .font(AppTypography.caption())
                                .foregroundStyle(InkMockup.captionColor)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                                .foregroundStyle(InkMockup.captionColor.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Dosya seç", isPresented: $showSourcePicker, titleVisibility: .hidden) {
                        Button("Fotoğraf") { showPhotosPicker = true }
                        Button("Dosyalar") { showFileImporter = true }
                        Button("Vazgeç", role: .cancel) {}
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkError)
                    }

                    InkMockPrimaryButton(title: picked == nil ? "Dosya seç" : "Yükle", isLoading: isUploading) {
                        if picked == nil {
                            showSourcePicker = true
                        } else {
                            Task { await upload() }
                        }
                    }
                    .disabled(isUploading)
                }
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.vertical, 20)
        }
        .studentScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $showPhotosPicker, selection: $pickerItem, matching: .images)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: HomeworkPickedFile.allowedTypes) { result in
            switch result {
            case .success(let url):
                do { picked = try HomeworkPickedFile.load(from: url) }
                catch { errorMessage = (error as? LocalizedError)?.errorDescription ?? "Dosya okunamadı." }
            case .failure:
                errorMessage = "Dosya seçilemedi."
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                do { picked = try await HomeworkPickedFile.load(from: item) }
                catch { errorMessage = (error as? LocalizedError)?.errorDescription ?? "Fotoğraf okunamadı." }
                pickerItem = nil
            }
        }
    }

    private func upload() async {
        guard let picked else { return }
        isUploading = true
        errorMessage = nil
        defer { isUploading = false }
        do {
            try await catalog.submitHomework(assignmentId: item.assignmentId, data: picked.data, contentType: picked.contentType)
            submitted = true
            _ = try? await catalog.fetchBadgeProgress()
            await onSubmitted?()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}

private struct HomeworkPickedFile {
    static let allowedTypes: [UTType] = [.png, .jpeg, .pdf]
    static let maxBytes = 10 * 1024 * 1024

    let name: String
    let data: Data
    let contentType: String

    enum FileError: LocalizedError {
        case unsupported
        case tooLarge
        case unreadable

        var errorDescription: String? {
            switch self {
            case .unsupported: return "Sadece PNG, JPEG, JPG veya PDF yükleyebilirsin."
            case .tooLarge: return "Dosya en fazla 10 MB olabilir."
            case .unreadable: return "Dosya okunamadı."
            }
        }
    }

    static func load(from url: URL) throws -> Self {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        return try make(name: url.lastPathComponent, data: data, type: UTType(filenameExtension: url.pathExtension))
    }

    static func load(from item: PhotosPickerItem) async throws -> Self {
        guard let data = try await item.loadTransferable(type: Data.self) else { throw FileError.unreadable }
        if let jpeg = HomeworkPickedFile.normalizedImage(data) {
            return try make(name: "odev.jpg", data: jpeg, type: .jpeg)
        }
        throw FileError.unsupported
    }

    private static func make(name: String, data: Data, type: UTType?) throws -> Self {
        guard data.count <= maxBytes else { throw FileError.tooLarge }
        if type?.conforms(to: .pdf) == true || data.starts(with: [0x25, 0x50, 0x44, 0x46]) {
            return Self(name: name, data: data, contentType: "application/pdf")
        }
        if type?.conforms(to: .png) == true || data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return Self(name: name, data: data, contentType: "image/png")
        }
        if type?.conforms(to: .jpeg) == true || (data.count > 2 && data[0] == 0xFF && data[1] == 0xD8) {
            return Self(name: name, data: data, contentType: "image/jpeg")
        }
        if let jpeg = normalizedImage(data) {
            return Self(name: name, data: jpeg, contentType: "image/jpeg")
        }
        throw FileError.unsupported
    }

    private static func normalizedImage(_ data: Data) -> Data? {
        #if canImport(UIKit)
        return UIImage(data: data)?.jpegData(compressionQuality: 0.85)
        #else
        return nil
        #endif
    }
}
