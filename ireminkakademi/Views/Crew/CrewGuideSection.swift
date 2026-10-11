import SwiftUI
import UniformTypeIdentifiers

struct CrewGuideSection: View {
    private let service = LearningAdminService()
    @State private var guide: GuideDTO?
    @State private var showPicker = false
    @State private var isUploading = false
    @State private var errorMessage: String?

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Satın alma yapan öğrenciler (Light / Plus / Life Plus) ana sayfada bu PDF’i görür. Deneme sürümü göremez.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: guide?.available == true ? "checkmark.circle.fill" : "book.closed")
                        .foregroundStyle(guide?.available == true ? Color.inkSage : .secondary)
                    Text(guide?.available == true ? "Rehber yayında" : "Henüz PDF yok")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                }

                if isUploading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Kitap yükleniyor… Wi‑Fi’da bırak, kapatma.")
                            .font(.system(size: 13))
                    }
                } else {
                    Button("PDF yükle / değiştir") { showPicker = true }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("INK AKADEMI Rehberi")
        }
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.pdf]) { result in
            if case .success(let url) = result {
                Task { await upload(url) }
            }
        }
        .alert("Hata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .task { guide = try? await service.fetchGuide() }
    }

    private func upload(_ url: URL) async {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        isUploading = true
        defer { isUploading = false }
        do {
            let dest = FileManager.default.temporaryDirectory.appendingPathComponent("ink-guide-upload.pdf")
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.copyItem(at: url, to: dest)
            defer { try? FileManager.default.removeItem(at: dest) }
            guide = try await service.uploadGuidePDF(fileURL: dest)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
