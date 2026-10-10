import SwiftUI

struct ContactSupportView: View {
    @State private var senderEmail: String = ""
    @State private var messageBody: String = ""
    @State private var showSentConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Selam! Sana yardımcı olabilmemiz için yaşadığın sorunu aşağı yazarak bize ulaş. <3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.inkTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("E-posta")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.inkTextTertiary)
                    TextField("ornek@mail.com", text: $senderEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(AppSpacing.md)
                        .background(Color.inkSurface.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Mesajın")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.inkTextTertiary)
                    TextEditor(text: $messageBody)
                        .frame(minHeight: 140)
                        .padding(AppSpacing.sm)
                        .scrollContentBackground(.hidden)
                        .background(Color.inkSurface.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous))
                }

                InkButton(title: "Gönder", isDisabled: !canSend) {
                    openMailComposer()
                }
            }
            .padding(AppSpacing.screenH)
            .padding(.vertical, AppSpacing.lg)
        }
        .inkPageBackground()
        .navigationTitle("Bize Ulaş")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Mail uygulaması", isPresented: $showSentConfirmation) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Mesajını \(AppLegalConfig.supportEmail) adresine göndermek için Mail uygulamasını aç.")
        }
    }

    private var canSend: Bool {
        senderEmail.contains("@") && messageBody.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }

    private func openMailComposer() {
        let subject = "Ink Akademi Destek"
        let body = messageBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mail = AppLegalConfig.supportEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let from = senderEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(mail)?subject=\(subject)&body=\(body)&from=\(from)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showSentConfirmation = true
            }
        }
    }
}
