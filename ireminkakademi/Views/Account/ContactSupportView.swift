import SwiftUI

struct ContactSupportView: View {
    @Environment(\.inkStudioChrome) private var studio
    @State private var userEmail = ""
    @State private var message = ""
    @State private var mailError: String?

    private var textPrimary: Color { studio ? InkMockup.textPrimary : InkAuth.textPrimary }
    private var caption: Color { studio ? InkMockup.captionColor : InkAuth.captionColor }
    private var placeholder: Color { studio ? InkMockup.placeholderColor : InkAuth.placeholderColor }
    private var fieldFill: Color { studio ? InkMockup.fieldFill : InkAuth.fieldFill }
    private var fieldBorder: Color { studio ? InkMockup.fieldBorder : InkAuth.fieldBorder }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Selam!")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(textPrimary)
                    Text("Sana yardımcı olabilmemiz için yaşadığın sorunu aşağı yazarak bize ulaş. <3")
                        .font(.system(size: 16))
                        .foregroundStyle(caption)
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

                TextField(text: $message, prompt: Text("Açıklama").foregroundStyle(placeholder), axis: .vertical) {
                    Text("Açıklama")
                }
                .lineLimit(6...12)
                .font(.system(size: 16))
                .foregroundStyle(textPrimary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(fieldFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(fieldBorder, lineWidth: 1)
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
