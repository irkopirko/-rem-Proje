import SwiftUI

struct ForgotPasswordView: View {
    let authService: AuthServiceProtocol
    @Binding var path: NavigationPath

    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var step = 1
    @State private var isLoading = false
    @State private var message: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            Text("Endişelenme.")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(InkAuth.textPrimary)

            Text("Hesabının kaydolduğu maili gir. Hesabını kurtarmana yardımcı olacağız.")
                .font(.system(size: 15))
                .foregroundStyle(InkAuth.captionColor)
                .fixedSize(horizontal: false, vertical: true)

            if step == 1 {
                InkMockTextField(placeholder: "E-mail", text: $email, textContentType: .emailAddress, keyboardType: .emailAddress, autocapitalization: .never)
                    .padding(.top, 8)

                InkMockPrimaryButton(title: "Kod Gönder", isLoading: isLoading) {
                    Task { await sendCode() }
                }
            } else {
                InkMockTextField(placeholder: "6 haneli kod", text: $code, textContentType: .oneTimeCode, keyboardType: .numberPad)
                    .padding(.top, 8)
                InkMockTextField(placeholder: "Yeni şifre", text: $newPassword, isSecure: true, textContentType: .newPassword)
                InkMockPrimaryButton(title: "Şifreyi Sıfırla", isLoading: isLoading) {
                    Task { await reset() }
                }
            }

            if let localCode = (authService as? LocalAuthService)?.lastIssuedCode, step == 2 {
                Text("Geliştirme modu — sunucu bağlı değil. Kodun: \(localCode)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(InkAuth.captionColor)
            }

            if let message {
                Text(message).font(.system(size: 13)).foregroundStyle(Color.inkSage)
            }
            if let errorMessage {
                Text(errorMessage).font(.system(size: 13)).foregroundStyle(Color.inkError)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, InkMockup.screenHorizontal)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inkMotionBackground()
    }

    private func sendCode() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.forgotPassword(email: email)
            step = 2
            message = "Kod e-postana gönderildi."
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }

    private func reset() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.resetPassword(email: email, code: code, newPassword: newPassword)
            path.removeLast(path.count)
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}
