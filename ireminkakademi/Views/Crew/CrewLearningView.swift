import AVFoundation
import CoreTransferable
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Modül listesi

struct CrewLearningView: View {
    private let service = LearningAdminService()
    @State private var programs: [EducationProgramDTO] = []
    @State private var modules: [ModuleDTO] = []
    @State private var videoServiceConfigured = true
    @State private var didLoad = false
    @State private var showNewProgram = false
    @State private var showNewModule = false
    @State private var pendingDelete: ModuleDTO?
    @State private var errorMessage: String?
    private let uploads = VideoUploadManager.shared

    var body: some View {
        NavigationStack {
            List {
                CrewGuideSection()

                if !videoServiceConfigured {
                    Section {
                        Label {
                            Text("Video servisi henüz bağlanmadı. Eğitim ve modül oluşturabilirsin; video yüklemek için Bunny Stream ayarlarının sunucuya girilmesi gerekiyor.")
                                .font(.system(size: 13))
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        }
                    }
                }

                if uploads.activeCount > 0 {
                    Section {
                        Label("\(uploads.activeCount) video yükleniyor. Uygulamayı açık tutman yüklemeyi hızlandırır.", systemImage: "icloud.and.arrow.up")
                            .font(.system(size: 13))
                    }
                }

                if programs.isEmpty, modules.isEmpty, didLoad {
                    ContentUnavailableView {
                        Label("Henüz eğitim yok", systemImage: "rectangle.stack.badge.play")
                    } description: {
                        Text("Önce bir eğitim ekle (Ink Akademi veya başka bir program). Sonra o eğitime modül, modüle de ders videosu ekle.")
                    } actions: {
                        Button("Eğitim ekle") { showNewProgram = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.black)
                    }
                } else {
                    ForEach(programs) { program in
                        Section {
                            NavigationLink {
                                CrewProgramEditorView(existing: program) { Task { await load() } }
                            } label: {
                                programRow(program)
                            }
                            ForEach(modules(in: program)) { module in
                                NavigationLink {
                                    CrewModuleDetailView(
                                        module: module,
                                        programs: programs,
                                        videoServiceConfigured: videoServiceConfigured
                                    ) {
                                        Task { await load() }
                                    }
                                } label: {
                                    moduleRow(module)
                                }
                                .swipeActions {
                                    Button("Sil", role: .destructive) { pendingDelete = module }
                                }
                            }
                        } header: {
                            Text("\(program.numberLabel). \(program.title)")
                                .textCase(nil)
                        }
                    }

                    let orphans = modules.filter { module in
                        guard let id = module.educationProgramId else { return true }
                        return !programs.contains(where: { $0.id == id })
                    }
                    if !orphans.isEmpty {
                        Section("Diğer") {
                            ForEach(orphans) { module in
                                NavigationLink {
                                    CrewModuleDetailView(
                                        module: module,
                                        programs: programs,
                                        videoServiceConfigured: videoServiceConfigured
                                    ) {
                                        Task { await load() }
                                    }
                                } label: {
                                    moduleRow(module)
                                }
                                .swipeActions {
                                    Button("Sil", role: .destructive) { pendingDelete = module }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Eğitim")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Eğitim ekle", systemImage: "rectangle.stack.badge.plus") { showNewProgram = true }
                        Button("Modül ekle", systemImage: "plus") { showNewModule = true }
                            .disabled(programs.isEmpty)
                    } label: {
                        Label("Ekle", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $showNewProgram) {
                CrewProgramEditorView(existing: nil) { Task { await load() } }
            }
            .navigationDestination(isPresented: $showNewModule) {
                CrewModuleEditorView(existing: nil, programs: programs) { Task { await load() } }
            }
            .refreshable { await load() }
            .task {
                uploads.resumeAll()
                guard !didLoad else { return }
                await load()
                didLoad = true
            }
            .confirmationDialog(
                "\"\(pendingDelete?.title ?? "")\" modülü ve içindeki tüm videolar kalıcı olarak silinecek.",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Modülü sil", role: .destructive) {
                    guard let module = pendingDelete else { return }
                    Task {
                        do { try await service.deleteModule(id: module.id) } catch { errorMessage = AuthErrorMessage.from(error) }
                        await load()
                    }
                }
            }
            .alert("Hata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func modules(in program: EducationProgramDTO) -> [ModuleDTO] {
        modules.filter { $0.educationProgramId == program.id }
    }

    private func programRow(_ program: EducationProgramDTO) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(program.title).font(.system(size: 16, weight: .semibold)).lineLimit(2)
                if program.isPublished == false {
                    Text("Taslak")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2), in: Capsule())
                }
            }
            Text("\(program.moduleCount) modül · \(program.videoCount) ders")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func moduleRow(_ module: ModuleDTO) -> some View {
        HStack(spacing: 12) {
            Text(module.numberLabel)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 40, height: 40)
                .background(Circle().fill(InkMockup.fieldFill))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(module.title).font(.system(size: 16, weight: .semibold)).lineLimit(2)
                    if module.isPublished == false {
                        Text("Taslak")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2), in: Capsule())
                    }
                }
                Text("\(module.videoCount) video · \(module.readyCount ?? 0) hazır")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func load() async {
        do {
            let resp = try await service.fetchModules()
            programs = resp.programs
            modules = resp.modules
            videoServiceConfigured = resp.videoServiceConfigured
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}

// MARK: - Modül düzenleyici

struct CrewProgramEditorView: View {
    let existing: EducationProgramDTO?
    let onSaved: () -> Void

    private let service = LearningAdminService()
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var instructorName = ""
    @State private var isPublished = true
    @State private var isSaving = false
    @State private var confirmDelete = false
    @State private var errorMessage: String?
    @State private var didLoad = false

    private static let descriptionLimit = 10000

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CrewEditorSection(title: "Eğitim başlığı") {
                    CrewTextField(placeholder: "Örn. INK AKADEMİ Eğitimi", text: $title, font: .system(size: 18, weight: .semibold))
                }

                CrewEditorSection(title: "Eğitmen") {
                    CrewTextField(placeholder: "Örn. Vural Emekçi", text: $instructorName)
                }

                CrewEditorSection(title: "Açıklama", footer: "Bu eğitim programında neler var, kimlere hitap ediyor…") {
                    CrewLongTextEditor(placeholder: "Eğitimi anlat…", text: $description, limit: Self.descriptionLimit, minHeight: 220)
                }

                CrewEditorSection(title: "Görünürlük", footer: "Taslak eğitimler öğrencilere gösterilmez. Modüllerini ekleyip hazır olduğunda yayınlayabilirsin.") {
                    Toggle("Öğrencilere yayınla", isOn: $isPublished)
                        .tint(.black)
                        .padding(14)
                        .background(InkMockup.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if existing == nil {
                    Label("Kaydettikten sonra bu eğitime modül, modüllere de ders videosu ekleyebilirsin.", systemImage: "rectangle.stack.badge.plus")
                        .font(.system(size: 13))
                        .foregroundStyle(InkMockup.captionColor)
                }

                if let existing {
                    if (existing.moduleCount) > 0 {
                        Text("Bu eğitimde \(existing.moduleCount) modül var. Silmek için önce modülleri taşı veya sil.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    } else {
                        Button("Eğitimi sil", role: .destructive) { confirmDelete = true }
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(existing == nil ? "Yeni eğitim" : "Eğitimi düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button("Kaydet") { Task { await save() } }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
        .disabled(isSaving)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            title = existing?.title ?? ""
            description = existing?.description ?? ""
            instructorName = existing?.instructorName ?? ""
            isPublished = existing?.isPublished ?? true
        }
        .confirmationDialog("Eğitim kalıcı olarak silinecek.", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Eğitimi sil", role: .destructive) { Task { await deleteProgram() } }
        }
        .alert("Kaydedilemedi", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && description.count <= Self.descriptionLimit
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let draft = ProgramDraft(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            instructorName: instructorName.trimmingCharacters(in: .whitespacesAndNewlines),
            isPublished: isPublished
        )
        do {
            if let existing {
                try await service.updateProgram(id: existing.id, draft)
            } else {
                _ = try await service.createProgram(draft)
            }
            onSaved()
            dismiss()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }

    private func deleteProgram() async {
        guard let existing else { return }
        do {
            try await service.deleteProgram(id: existing.id)
            onSaved()
            dismiss()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}

// MARK: - Modül düzenleyici

struct CrewModuleEditorView: View {
    let existing: ModuleDTO?
    var programs: [EducationProgramDTO] = []
    let onSaved: () -> Void

    private let service = LearningAdminService()
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var isPublished = true
    @State private var educationProgramId = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var didLoad = false

    private static let descriptionLimit = 10000

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !programs.isEmpty {
                    CrewEditorSection(title: "Eğitim", footer: "Bu modül hangi eğitim programının altında görünecek.") {
                        Picker("Eğitim", selection: $educationProgramId) {
                            ForEach(programs) { program in
                                Text(program.title).tag(program.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.black)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(InkMockup.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                CrewEditorSection(title: "Modül başlığı") {
                    CrewTextField(placeholder: "Örn. Linework temelleri", text: $title, font: .system(size: 18, weight: .semibold))
                }

                CrewEditorSection(title: "Açıklama", footer: "Bu modülde neler öğrenilecek, hangi seviyeye uygun, hangi malzemeler gerekli…") {
                    CrewLongTextEditor(placeholder: "Modülü detaylıca anlat…", text: $description, limit: Self.descriptionLimit, minHeight: 260)
                }

                CrewEditorSection(title: "Görünürlük", footer: "Taslak modüller öğrencilere gösterilmez. Videolarını yükleyip hazır olduğunda yayınlayabilirsin.") {
                    Toggle("Öğrencilere yayınla", isOn: $isPublished)
                        .tint(.black)
                        .padding(14)
                        .background(InkMockup.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if existing == nil {
                    Label("Kaydettikten sonra modülü açıp videolarını ekleyebilirsin.", systemImage: "video.badge.plus")
                        .font(.system(size: 13))
                        .foregroundStyle(InkMockup.captionColor)
                }
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(existing == nil ? "Yeni modül" : "Modülü düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button("Kaydet") { Task { await save() } }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
        .disabled(isSaving)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            title = existing?.title ?? ""
            description = existing?.description ?? ""
            isPublished = existing?.isPublished ?? true
            educationProgramId = existing?.educationProgramId ?? programs.first?.id ?? ""
        }
        .alert("Kaydedilemedi", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && description.count <= Self.descriptionLimit
            && (programs.isEmpty || !educationProgramId.isEmpty)
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let draft = ModuleDraft(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            isPublished: isPublished,
            educationProgramId: educationProgramId.isEmpty ? nil : educationProgramId
        )
        do {
            if let existing {
                try await service.updateModule(id: existing.id, draft)
            } else {
                _ = try await service.createModule(draft)
            }
            onSaved()
            dismiss()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}

// MARK: - Modül detayı (videolar)

struct CrewModuleDetailView: View {
    @State var module: ModuleDTO
    var programs: [EducationProgramDTO] = []
    let videoServiceConfigured: Bool
    let onChanged: () -> Void

    private let service = LearningAdminService()
    private let uploads = VideoUploadManager.shared
    @State private var videos: [VideoDTO] = []
    @State private var didLoad = false
    @State private var showNewVideo = false
    @State private var showEditModule = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(module.title).font(.system(size: 20, weight: .bold))
                    if let desc = module.description, !desc.isEmpty {
                        Text(desc).font(.system(size: 14)).foregroundStyle(.secondary).lineLimit(6)
                    }
                    Button("Modülü düzenle") { showEditModule = true }
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.vertical, 4)
            }

            let localJobs = uploads.jobs(inModule: module.id).filter { job in !videos.contains { $0.id == job.videoId } }
            Section("Videolar") {
                if videos.isEmpty, localJobs.isEmpty, didLoad {
                    Text("Henüz video yok. Sağ üstteki + ile ekle.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                ForEach(videos) { video in
                    NavigationLink {
                        CrewVideoEditorView(moduleId: module.id, existing: video, videoServiceConfigured: videoServiceConfigured) {
                            Task { await load() }
                        }
                    } label: {
                        CrewVideoRow(video: video, uploads: uploads)
                    }
                }
            }
        }
        .navigationTitle("Modül \(module.numberLabel)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewVideo = true } label: { Label("Video ekle", systemImage: "plus") }
                    .disabled(!videoServiceConfigured)
            }
        }
        .navigationDestination(isPresented: $showNewVideo) {
            CrewVideoEditorView(moduleId: module.id, existing: nil, videoServiceConfigured: videoServiceConfigured) {
                Task { await load() }
            }
        }
        .navigationDestination(isPresented: $showEditModule) {
            CrewModuleEditorView(existing: module, programs: programs) {
                onChanged()
                Task { await reloadModule() }
            }
        }
        .refreshable { await load() }
        .task {
            if !didLoad {
                await load()
                didLoad = true
            }
            // İşlenen videoların durumunu periyodik olarak yenile.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                if videos.contains(where: { $0.status == .processing || $0.status == .awaitingUpload }) {
                    await load()
                }
            }
        }
        .alert("Hata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func load() async {
        do {
            videos = try await service.fetchVideos(moduleId: module.id)
        } catch {
            if !didLoad { errorMessage = AuthErrorMessage.from(error) }
        }
    }

    private func reloadModule() async {
        if let resp = try? await service.fetchModules(), let fresh = resp.modules.first(where: { $0.id == module.id }) {
            module = fresh
        }
    }
}

private struct CrewVideoRow: View {
    let video: VideoDTO
    let uploads: VideoUploadManager

    var body: some View {
        HStack(spacing: 12) {
            VideoThumbnail(url: video.thumbnailURL)
                .frame(width: 96, height: 54)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(video.numberLabel).").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                    Text(video.title).font(.system(size: 15, weight: .semibold)).lineLimit(2)
                }
                statusLine
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusLine: some View {
        if let phase = uploads.phases[video.id] {
            switch phase {
            case .failed(let message):
                HStack {
                    Label(message, systemImage: "exclamationmark.circle.fill").foregroundStyle(Color.inkError)
                    Button("Tekrar dene") { uploads.retry(video.id) }.buttonStyle(.borderless)
                }
                .font(.system(size: 12))
            case .finishing:
                Label("Yükleme tamamlanıyor…", systemImage: "checkmark.icloud").font(.system(size: 12)).foregroundStyle(.secondary)
            case .waiting, .uploading:
                let value = uploads.progress[video.id] ?? 0
                VStack(alignment: .leading, spacing: 3) {
                    ProgressView(value: value).tint(.black)
                    Text("Yükleniyor %\(Int(value * 100))").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        } else {
            HStack(spacing: 6) {
                statusBadge
                if video.status == .ready {
                    Text(video.durationLabel)
                    if let q = video.qualityLabel { Text(q).fontWeight(.bold) }
                }
                if !video.isPublished { Text("· Taslak").foregroundStyle(.orange) }
                Text(video.allowTrial ? "· Deneme açık" : "· Abonelere")
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
    }

    private var statusBadge: some View {
        let color: Color = switch video.status {
        case .ready: .green
        case .processing: .blue
        case .awaitingUpload: .orange
        case .failed: .red
        }
        return Label(video.status.displayName, systemImage: "circle.fill")
            .labelStyle(StatusDotLabelStyle(color: color))
    }
}

private struct StatusDotLabelStyle: LabelStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            configuration.title
        }
    }
}

// MARK: - Video ekle / düzenle

/// Fotoğraflar'dan seçilen videonun orijinal dosyası (yeniden kodlama yapılmaz).
nonisolated struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            Self(url: try VideoUploadStaging.copyIntoStaging(received.file))
        }
    }
}

struct CrewVideoEditorView: View {
    let moduleId: String
    let existing: VideoDTO?
    let videoServiceConfigured: Bool
    let onSaved: () -> Void

    private let service = LearningAdminService()
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var isPublished = true
    @State private var allowTrial = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showFileImporter = false
    @State private var stagedFile: URL?
    @State private var fileInfo: String?
    @State private var isImporting = false
    @State private var isSaving = false
    @State private var confirmDelete = false
    @State private var errorMessage: String?
    @State private var didLoad = false

    private static let descriptionLimit = 10000

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let existing, existing.status == .ready {
                    NavigationLink {
                        VideoPlayerScreen(video: existing, reportsProgress: false)
                    } label: {
                        VideoThumbnail(url: existing.thumbnailURL)
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .overlay(Image(systemName: "play.circle.fill").font(.system(size: 48)).foregroundStyle(.white))
                    }
                    .buttonStyle(.plain)
                }

                CrewEditorSection(title: "Video başlığı") {
                    CrewTextField(placeholder: "Örn. İğne seçimi ve makine ayarı", text: $title, font: .system(size: 18, weight: .semibold))
                }

                CrewEditorSection(title: "Açıklama", footer: "Videoda anlatılanlar, önemli noktalar, gerekli malzemeler…") {
                    CrewLongTextEditor(placeholder: "Videoyu anlat…", text: $description, limit: Self.descriptionLimit, minHeight: 220)
                }

                if existing == nil {
                    CrewEditorSection(
                        title: "Video dosyası",
                        footer: "Video çektiğin/yüklediğin kalitede (4K dahil) saklanır; öğrenciler bağlantılarına göre en yüksek kaliteyi takılmadan izler. Büyük dosyalar parça parça yüklenir, bağlantı koparsa kaldığı yerden devam eder."
                    ) {
                        videoPickerArea
                    }
                }

                CrewEditorSection(title: "Görünürlük") {
                    Toggle("Öğrencilere yayınla", isOn: $isPublished)
                        .tint(.black)
                        .padding(14)
                        .background(InkMockup.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                CrewEditorSection(
                    title: "Kimler izleyebilir?",
                    footer: "Light, Plus ve Life Plus üyeleri her zaman izler. Deneme sürümüne açık dersen deneme hesabı olan öğrenciler de bu videoyu görür."
                ) {
                    VStack(spacing: 0) {
                        audienceRow(
                            title: "Satın alma ve izinli üyeler",
                            subtitle: "Light, Plus, Life Plus",
                            selected: !allowTrial
                        ) { allowTrial = false }
                        Divider().padding(.leading, 14)
                        audienceRow(
                            title: "Deneme sürümü dahil",
                            subtitle: "Deneme + satın alma",
                            selected: allowTrial
                        ) { allowTrial = true }
                    }
                    .background(InkMockup.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if existing != nil {
                    Button("Videoyu sil", role: .destructive) { confirmDelete = true }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(existing == nil ? "Yeni video" : "Videoyu düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button(existing == nil ? "Yükle" : "Kaydet") { Task { await save() } }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
        .disabled(isSaving)
        .onAppear(perform: populate)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await importFromPhotos(item) }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.movie]) { result in
            if case .success(let url) = result { importFromFiles(url) }
        }
        .onDisappear {
            // Kaydedilmeden çıkıldıysa geçici kopyayı temizle.
            if let stagedFile, !isSaving { try? FileManager.default.removeItem(at: stagedFile) }
        }
        .confirmationDialog("Video kalıcı olarak silinecek.", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Videoyu sil", role: .destructive) { Task { await deleteVideo() } }
        }
        .alert("Hata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var videoPickerArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isImporting {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Video hazırlanıyor…").font(.system(size: 14))
                }
                .frame(maxWidth: .infinity, minHeight: 80)
            } else if let stagedFile {
                HStack(spacing: 12) {
                    Image(systemName: "film.fill").font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(stagedFile.lastPathComponent).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        if let fileInfo { Text(fileInfo).font(.system(size: 12)).foregroundStyle(.secondary) }
                    }
                    Spacer()
                    Button {
                        try? FileManager.default.removeItem(at: stagedFile)
                        self.stagedFile = nil
                        fileInfo = nil
                        pickerItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(InkMockup.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(spacing: 10) {
                PhotosPicker(selection: $pickerItem, matching: .videos, preferredItemEncoding: .current) {
                    Label("Galeriden seç", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                Button { showFileImporter = true } label: {
                    Label("Dosyalardan", systemImage: "folder")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
            }
            .tint(.black)
            .disabled(isImporting || !videoServiceConfigured)
        }
    }

    private func audienceRow(title: String, subtitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? Color.black : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(.primary)
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              description.count <= Self.descriptionLimit,
              !isImporting else { return false }
        return existing != nil || (stagedFile != nil && videoServiceConfigured)
    }

    private func populate() {
        guard !didLoad else { return }
        didLoad = true
        title = existing?.title ?? ""
        description = existing?.description ?? ""
        isPublished = existing?.isPublished ?? true
        allowTrial = existing?.allowTrial ?? false
    }

    private func importFromPhotos(_ item: PhotosPickerItem) async {
        isImporting = true
        defer { isImporting = false }
        do {
            guard let movie = try await item.loadTransferable(type: PickedMovie.self) else {
                errorMessage = "Video alınamadı."
                return
            }
            replaceStaged(with: movie.url)
        } catch {
            errorMessage = "Video alınamadı: \(error.localizedDescription)"
        }
    }

    private func importFromFiles(_ url: URL) {
        isImporting = true
        defer { isImporting = false }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            replaceStaged(with: try VideoUploadStaging.copyIntoStaging(url))
        } catch {
            errorMessage = "Dosya kopyalanamadı: \(error.localizedDescription)"
        }
    }

    private func replaceStaged(with url: URL) {
        if let stagedFile { try? FileManager.default.removeItem(at: stagedFile) }
        stagedFile = url
        Task { fileInfo = await Self.describe(url) }
    }

    private static func describe(_ url: URL) async -> String {
        var parts: [String] = []
        if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
            parts.append(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
        }
        let asset = AVURLAsset(url: url)
        if let duration = try? await asset.load(.duration), duration.seconds.isFinite {
            let total = Int(duration.seconds)
            parts.append(String(format: "%d:%02d", total / 60, total % 60))
        }
        if let track = try? await asset.loadTracks(withMediaType: .video).first,
           let size = try? await track.load(.naturalSize) {
            parts.append("\(Int(abs(size.width)))×\(Int(abs(size.height)))")
        }
        return parts.joined(separator: " · ")
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let draft = VideoDraft(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            isPublished: isPublished,
            allowTrial: allowTrial
        )
        do {
            if let existing {
                try await service.updateVideo(id: existing.id, draft)
            } else if let stagedFile {
                let (video, credentials) = try await service.createVideo(moduleId: moduleId, draft)
                VideoUploadManager.shared.enqueue(video: video, credentials: credentials, stagedFile: stagedFile)
                self.stagedFile = nil
            }
            onSaved()
            dismiss()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }

    private func deleteVideo() async {
        guard let existing else { return }
        do {
            VideoUploadManager.shared.cancel(existing.id)
            try await service.deleteVideo(id: existing.id)
            onSaved()
            dismiss()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}
