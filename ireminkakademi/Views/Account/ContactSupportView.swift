import SwiftUI

struct ContactSupportView: View {
    @State private var userEmail = ""
    @State private var message = ""
    @State private var mailError: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Selam!")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(InkMockup.textPrimary)
                    Text("Sana yardımcı olabilmemiz için yaşadığın sorunu aşağı yazarak bize ulaş. <3")
                        .font(.system(size: 16))
                        .foregroundStyle(InkMockup.captionColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 40)

                InkMockTextField(
                    placeholder: "E-mail",
                    text: $userEmail,
                    textContentType: .emailAddress,
                    keyboardType: .emailAddress,
                    autocapitalization: .never
                )

                TextField(text: $message, prompt: Text("Açıklama").foregroundStyle(InkMockup.placeholderColor), axis: .vertical) {
                    Text("Açıklama")
                }
                .lineLimit(6...12)
                .font(.system(size: 16))
                .foregroundStyle(InkMockup.textPrimary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(InkMockup.fieldFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(InkMockup.fieldBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                InkMockPrimaryButton(title: "Gönder") { openMail() }

                if let mailError {
                    Text(mailError).font(.system(size: 13)).foregroundStyle(Color.inkError)
                }
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.bottom, 24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .studentScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openMail() {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            mailError = "Lütfen yaşadığın sorunu yaz."
            return
        }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppLegalConfig.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Ink Akademi Destek"),
            URLQueryItem(name: "body", value: "Gönderen: \(userEmail)\n\n\(trimmed)"),
        ]
        guard let url = components.url else {
            mailError = "Mail uygulaması açılamadı."
            return
        }
        UIApplication.shared.open(url) { opened in
            if !opened {
                mailError = "Cihazda kurulu bir mail uygulaması bulunamadı. \(AppLegalConfig.supportEmail) adresine yazabilirsin."
            }
        }
    }
}
