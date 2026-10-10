import SwiftUI
import SafariServices

struct LegalDocumentView: View {
    let title: String
    let url: URL

    var body: some View {
        LegalSafariView(url: url)
            .ignoresSafeArea()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LegalSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
