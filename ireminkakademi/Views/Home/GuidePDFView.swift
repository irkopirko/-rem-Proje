import PDFKit
import SwiftUI

struct GuidePDFScreen: View {
    @State private var localURL: URL?
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let localURL {
                PDFKitView(url: localURL)
            } else if isLoading {
                ProgressView("Rehber hazırlanıyor…")
                    .tint(InkMockup.accentPink)
                    .foregroundStyle(InkMockup.captionColor)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 36))
                        .foregroundStyle(InkMockup.accentPink)
                    Text(errorMessage ?? "Rehber henüz yüklenmedi.")
                        .font(.system(size: 15))
                        .foregroundStyle(InkMockup.captionColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .studentScreenBackground()
        .navigationTitle("INK AKADEMI Rehberin")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let guide = try await CatalogService().fetchGuide()
            guard let remote = guide.fileURL else {
                errorMessage = "Crew henüz rehberi yüklemedi."
                return
            }
            let (temp, _) = try await URLSession.shared.download(from: remote)
            let dest = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ink-akademi-rehberi.pdf")
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: temp, to: dest)
            localURL = dest
        } catch InkAPIError.paymentRequired {
            errorMessage = "Rehber yalnızca Light, Plus ve Life Plus üyelerine açık."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .clear
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}
