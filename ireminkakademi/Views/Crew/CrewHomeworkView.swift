import SwiftUI

struct CrewHomeworkView: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case homework = "Ödevler"
        case review = "Kontrol bekleyen"
        var id: String { rawValue }
    }

    private let service = HomeworkAdminServiceFactory.make()
    @State private var tab: Tab = .homework
    @State private var homework: [CrewHomeworkDTO] = []
    @State private var pending: [CrewHomeworkItem] = []
    @State private var didLoad = false
    @State private var errorMessage: String?
    @State private var showNew = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Görünüm", selection: $tab) {
                        ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                switch tab {
                case .homework: homeworkSection
                case .review: reviewSection
                }
            }
            .navigationTitle("Ödevler")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNew = true
                    } label: {
                        Label("Ödev ekle", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $showNew) {
                CrewHomeworkEditorView(service: service, existing: nil) { Task { await load() } }
            }
            .refreshable { await load() }
            .task {
                guard !didLoad else { return }
                didLoad = true
                await load()
            }
            .alert("Hata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var homeworkSection: some View {
        if homework.isEmpty {
            ContentUnavailableView {
                Label("Henüz ödev yok", systemImage: "doc.text")
            } description: {
                Text("Başlık, açıklama ve görsellerle yeni bir ödev oluştur. Ödev tüm öğrencilere atanır.")
            } actions: {
                Button("Ödev ekle") { showNew = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)
            }
        } else {
            Section {
                ForEach(homework) { item in
                    NavigationLink {
                        CrewHomeworkEditorView(service: service, existing: item) { Task { await load() } }
                    } label: {
                        row(item)
                    }
                }
                .onDelete { offsets in
                    let ids = offsets.map { homework[$0].id }
                    Task {
                        for id in ids { try? await service.delete(id: id) }
                        await load()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var reviewSection: some View {
        if pending.isEmpty {
            ContentUnavailableView("Kontrol bekleyen ödev yok", systemImage: "checkmark.seal")
        } else {
            Section {
                ForEach(pending) { item in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title).font(.headline)
                        Text("\(item.firstName) \(item.lastName)").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func row(_ item: CrewHomeworkDTO) -> some View {
        HStack(spacing: 12) {
            ProductImageView(url: item.gallery.first?.resolvedURL)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.system(size: 15, weight: .semibold)).lineLimit(2)
                Text(subtitle(item))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func subtitle(_ item: CrewHomeworkDTO) -> String {
        var parts = ["\(item.gallery.count) görsel"]
        if let assigned = item.assignedCount { parts.append("\(assigned) öğrenci") }
        if let submitted = item.submittedCount, submitted > 0 { parts.append("\(submitted) teslim") }
        if let due = HomeworkDateFormat.display(item.dueAt) { parts.append("Son: \(due)") }
        return parts.joined(separator: " · ")
    }

    private func load() async {
        do {
            homework = try await service.fetchAll()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
        if APIConfiguration.isConfigured {
            struct Resp: Decodable { let items: [CrewHomeworkItem] }
            if let resp: Resp = try? await InkAPIClient.shared.request("/v1/crew/homework/pending-review", authorized: true) {
                pending = resp.items
            }
        }
    }
}

enum HomeworkDateFormat {
    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    static func display(_ value: String?) -> String? {
        guard let date = parse(value) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
}

struct CrewHomeworkEditorView: View {
    let service: HomeworkAdminServicing
    let existing: CrewHomeworkDTO?
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var explanation = ""
    @State private var hasDueDate = false
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var images = CrewImageEditingModel()
    @State private var createdId: String?
    @State private var isSaving = false
    @State private var progressText: String?
    @State private var errorMessage: String?
    @State private var confirmDelete = false
    @State private var didLoad = false

    private static let explanationLimit = 10000

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CrewEditorSection(title: "Ödev başlığı") {
                    CrewTextField(placeholder: "Örn. Linework çalışması – 3 farklı kalınlık", text: $title, font: .system(size: 18, weight: .semibold))
                }

                CrewEditorSection(title: "Açıklama", footer: "Öğrencinin ne yapacağını adım adım yaz: teknik, malzeme, teslim şekli, değerlendirme kriterleri…") {
                    CrewLongTextEditor(
                        placeholder: "Ödevi detaylıca anlat…",
                        text: $explanation,
                        limit: Self.explanationLimit,
                        minHeight: 300
                    )
                }

                CrewEditorSection(
                    title: "Görseller (\(images.totalCount)/\(CrewImageEditingModel.maxImages))",
                    footer: "Örnek çalışmalar, referans görseller, şablonlar… İstediğin kadar ekleyebilirsin; ilk görsel kapak olur."
                ) {
                    CrewImageGrid(model: images)
                }

                CrewEditorSection(title: "Teslim tarihi") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Teslim tarihi belirle", isOn: $hasDueDate.animation())
                            .tint(.black)
                        if hasDueDate {
                            DatePicker("Son teslim", selection: $dueDate, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                                .environment(\.locale, Locale(identifier: "tr_TR"))
                        }
                    }
                    .padding(14)
                    .background(InkMockup.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if existing == nil {
                    Label("Ödev tüm öğrencilere atanır; sonradan kaydolan öğrenciler de görür.", systemImage: "person.3.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(InkMockup.captionColor)
                } else {
                    Button("Ödevi sil", role: .destructive) { confirmDelete = true }
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
        .navigationTitle(existing == nil ? "Yeni ödev" : "Ödevi düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button(existing == nil ? "Yayınla" : "Kaydet") { Task { await save() } }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
        .overlay(alignment: .bottom) { CrewProgressBadge(text: progressText) }
        .disabled(isSaving)
        .onAppear(perform: populate)
        .confirmationDialog("Ödev ve öğrencilerin bu ödeve ait teslimleri silinecek.", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Ödevi sil", role: .destructive) { Task { await deleteHomework() } }
        }
        .alert("Kaydedilemedi", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && explanation.count <= Self.explanationLimit
            && !images.isImporting
    }

    private func populate() {
        guard !didLoad else { return }
        didLoad = true
        title = existing?.title ?? ""
        explanation = existing?.explanation ?? ""
        if let due = HomeworkDateFormat.parse(existing?.dueAt) {
            hasDueDate = true
            dueDate = due
        }
        images.existing = existing?.gallery ?? []
    }

    private func save() async {
        isSaving = true
        defer {
            isSaving = false
            progressText = nil
        }
        let draft = HomeworkDraft(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            explanation: explanation.trimmingCharacters(in: .whitespacesAndNewlines),
            dueAt: hasDueDate ? dueDate : nil
        )
        do {
            let homeworkId: String
            if let id = createdId ?? existing?.id {
                try await service.update(id: id, draft)
                homeworkId = id
            } else {
                homeworkId = try await service.create(draft)
                createdId = homeworkId
            }
            try await images.commit(
                delete: { try await service.deleteImage(id: $0) },
                upload: { try await service.uploadImage(homeworkId: homeworkId, jpegData: $0) },
                progress: { progressText = "Görsel yükleniyor \($0)/\($1)" }
            )
            onSaved()
            dismiss()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }

    private func deleteHomework() async {
        guard let existing else { return }
        do {
            try await service.delete(id: existing.id)
            onSaved()
            dismiss()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}
