import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct AssignmentsListView: View {
    let container: DIContainer
    @State private var catalog = CatalogService()
    @State private var items: [HomeworkAssignmentDTO] = []
    @State private var showPaywall = false

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
                                Text("Ink Akademi senin üyelik sürümüne açık bir ödev yayınladığında burada görünür.")
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
            .overlay {
                if showPaywall {
                    ZStack {
                        Color.black.opacity(0.55).ignoresSafeArea().onTapGesture { showPaywall = false }
                        MembershipPaywallSheet { showPaywall = false }
                    }
                }
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
                    if item.isLocked(for: container.sessionUser) {
                        Button { showPaywall = true } label: {
                            homeworkLabel(item, showStatus: showStatus, locked: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            HomeworkDetailView(item: item, catalog: catalog) {
                                items = (try? await catalog.fetchHomework()) ?? items
                            }
                        } label: {
                            homeworkLabel(item, showStatus: showStatus, locked: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func homeworkLabel(_ item: HomeworkAssignmentDTO, showStatus: Bool, locked: Bool) -> some View {
        HStack(spacing: 10) {
            InkMockHomeworkPill(
                title: item.title,
                subtitle: locked ? "Üyelik ile açılır" : (item.isPastDue ? "Süresi doldu" : (showStatus ? statusLabel(item) : nil))
            )
            if locked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(InkMockup.accentPink)
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

    @State private var picked: [HomeworkPickedFile] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showFileImporter = false
    @State private var showSourcePicker = false
    @State private var showPhotosPicker = false
    @State private var isUploading = false
    @State private var uploadIndex = 0
    @State private var errorMessage: String?
    @State private var submitted = false

    private var canUpload: Bool {
        (item.status == "pending" || item.status == "graded_revise") && !item.isPastDue
    }

    private var existingBytes: Int {
        item.submittedFiles.reduce(0) { $0 + ($1.size ?? 0) }
    }

    private var pickedBytes: Int {
        picked.reduce(0) { $0 + $1.byteCount }
    }

    private var totalBytes: Int { existingBytes + pickedBytes }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(item.title)
                    .font(AppTypography.sectionHeading())
                    .foregroundStyle(InkMockup.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let due = HomeworkDateFormat.display(item.dueAt) {
                    Label(item.isPastDue ? "Süresi doldu: \(due)" : "Son teslim: \(due)", systemImage: item.isPastDue ? "calendar.badge.exclamationmark" : "calendar")
                        .font(AppTypography.mono(size: 12))
                        .foregroundStyle(item.isPastDue ? Color.inkError : InkMockup.captionColor)
                }

                if item.isPastDue && (item.status == "pending" || item.status == "graded_revise") {
                    Text("Teslim tarihi geçtiği için bu ödeve artık dosya yüklenemez.")
                        .font(AppTypography.body(size: 14))
                        .foregroundStyle(Color.inkError)
                        .fixedSize(horizontal: false, vertical: true)
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
                    Text(item.submittedFiles.count > 1
                         ? "Ödeviniz \(item.submittedFiles.count) dosya ile gönderildi. Değerlendiriyoruz."
                         : "Ödeviniz gönderildi. Değerlendiriyoruz.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.inkWarning)
                }

                if let score = item.latestScore {
                    Text("Not: \(score)")
                        .font(.headline)
                }

                if !item.submittedFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yüklü dosyalar")
                            .font(AppTypography.caption())
                            .foregroundStyle(InkMockup.captionColor)
                        ForEach(item.submittedFiles) { file in
                            if let url = file.resolvedURL {
                                Link(destination: url) {
                                    fileRow(name: file.name ?? "Dosya", bytes: file.size, systemImage: "paperclip")
                                }
                            } else {
                                fileRow(name: file.name ?? "Dosya", bytes: file.size, systemImage: "paperclip")
                            }
                        }
                    }
                }

                if canUpload && !submitted {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(picked) { file in
                            fileRow(name: file.name, bytes: file.byteCount, systemImage: file.contentType.contains("pdf") ? "doc.fill" : "photo") {
                                picked.removeAll { $0.id == file.id }
                            }
                        }

                        Button { showSourcePicker = true } label: {
                            VStack(spacing: 8) {
                                Text(picked.isEmpty ? "Dosya ekle" : "Başka dosya ekle")
                                    .font(AppTypography.cardTitle(size: 17))
                                    .foregroundStyle(InkMockup.textPrimary)
                                Text("PNG, JPEG, JPG, PDF · toplam en fazla 2 GB")
                                    .font(AppTypography.caption())
                                    .foregroundStyle(InkMockup.captionColor)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 120)
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

                        Text("Toplam \(HomeworkPickedFile.byteLabel(totalBytes)) / 2 GB")
                            .font(AppTypography.caption())
                            .foregroundStyle(InkMockup.captionColor)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkError)
                    }

                    InkMockPrimaryButton(
                        title: picked.isEmpty ? "Dosya seç" : (isUploading ? "Yükleniyor \(uploadIndex)/\(picked.count)" : "Yükle"),
                        isLoading: isUploading
                    ) {
                        if picked.isEmpty {
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
        .photosPicker(isPresented: $showPhotosPicker, selection: $pickerItems, maxSelectionCount: 30, matching: .images)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: HomeworkPickedFile.allowedTypes,
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls { addPicked(result: Result { try HomeworkPickedFile.load(from: url) }) }
            case .failure:
                errorMessage = "Dosya seçilemedi."
            }
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                for item in items {
                    do { try addPicked(try await HomeworkPickedFile.load(from: item)) }
                    catch { errorMessage = (error as? LocalizedError)?.errorDescription ?? "Fotoğraf okunamadı." }
                }
                pickerItems = []
            }
        }
    }

    private func fileRow(name: String, bytes: Int?, systemImage: String, onRemove: (() -> Void)? = nil) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(InkMockup.accentPink)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(AppTypography.body(size: 14))
                    .foregroundStyle(InkMockup.textPrimary)
                    .lineLimit(1)
                if let bytes {
                    Text(HomeworkPickedFile.byteLabel(bytes))
                        .font(AppTypography.caption())
                        .foregroundStyle(InkMockup.captionColor)
                }
            }
            Spacer(minLength: 0)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(InkMockup.captionColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func addPicked(result: Result<HomeworkPickedFile, Error>) {
        switch result {
        case .success(let file):
            do { try addPicked(file) }
            catch { errorMessage = (error as? LocalizedError)?.errorDescription ?? "Dosya eklenemedi." }
        case .failure(let error):
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Dosya okunamadı."
        }
    }

    private func addPicked(_ file: HomeworkPickedFile) throws {
        if existingBytes + pickedBytes + file.byteCount > HomeworkPickedFile.maxTotalBytes {
            throw HomeworkPickedFile.FileError.tooLarge
        }
        picked.append(file)
        errorMessage = nil
    }

    private func upload() async {
        guard !picked.isEmpty else { return }
        isUploading = true
        uploadIndex = 0
        errorMessage = nil
        defer { isUploading = false }
        do {
            let queue = picked
            for (index, file) in queue.enumerated() {
                uploadIndex = index + 1
                try await catalog.uploadHomeworkFile(assignmentId: item.assignmentId, file: file)
                picked.removeAll { $0.id == file.id }
            }
            try await catalog.finalizeHomework(assignmentId: item.assignmentId)
            submitted = true
            _ = try? await catalog.fetchBadgeProgress()
            await onSubmitted?()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}

struct HomeworkPickedFile: Identifiable {
    static let allowedTypes: [UTType] = [.png, .jpeg, .pdf]
    static let maxTotalBytes = 2 * 1024 * 1024 * 1024

    let id = UUID()
    let name: String
    let fileURL: URL
    let byteCount: Int
    let contentType: String

    enum FileError: LocalizedError {
        case unsupported
        case tooLarge
        case unreadable

        var errorDescription: String? {
            switch self {
            case .unsupported: return "Sadece PNG, JPEG, JPG veya PDF yükleyebilirsin."
            case .tooLarge: return "Dosyaların toplamı en fazla 2 GB olabilir."
            case .unreadable: return "Dosya okunamadı."
            }
        }
    }

    static func byteLabel(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    static func load(from url: URL) throws -> Self {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        let size = values.fileSize ?? 0
        let header = try readHeader(url)
        let mime = try detectMime(header: header, type: UTType(filenameExtension: url.pathExtension), data: nil)
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("hw-\(UUID().uuidString)-\(url.lastPathComponent)")
        try FileManager.default.copyItem(at: url, to: dest)
        return Self(name: url.lastPathComponent, fileURL: dest, byteCount: size, contentType: mime)
    }

    static func load(from item: PhotosPickerItem) async throws -> Self {
        guard let data = try await item.loadTransferable(type: Data.self) else { throw FileError.unreadable }
        guard let jpeg = normalizedImage(data) else { throw FileError.unsupported }
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent("hw-\(UUID().uuidString).jpg")
        try jpeg.write(to: dest)
        return Self(name: "odev.jpg", fileURL: dest, byteCount: jpeg.count, contentType: "image/jpeg")
    }

    private static func readHeader(_ url: URL) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return handle.readData(ofLength: 16)
    }

    private static func detectMime(header: Data, type: UTType?, data: Data?) throws -> String {
        if type?.conforms(to: .pdf) == true || header.starts(with: [0x25, 0x50, 0x44, 0x46]) {
            return "application/pdf"
        }
        if type?.conforms(to: .png) == true || header.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "image/png"
        }
        if type?.conforms(to: .jpeg) == true || (header.count > 2 && header[0] == 0xFF && header[1] == 0xD8) {
            return "image/jpeg"
        }
        if let data, normalizedImage(data) != nil {
            return "image/jpeg"
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
