import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    @Binding var path: NavigationPath
    @State private var showError = false

    var body: some View {
        AuthFormLayout {
            Image("inkakademi-logo")
                .resizable()
                .scaledToFit()
                .frame(height: 23)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 45)
                .padding(.bottom, 21)
                .accessibilityLabel("Ink Akademi")

            InkMockSubheading(text: "Merhaba! Hesabına giriş yap.")
                .padding(.top, 4)

            InkMockTextField(
                placeholder: "Kullanıcı adı veya e-mail",
                text: $viewModel.identifier,
                textContentType: .username,
                keyboardType: .emailAddress,
                autocapitalization: .never
            )

            InkMockTextField(
                placeholder: "Şifre",
                text: $viewModel.password,
                isSecure: true,
                textContentType: .password
            )

            InkMockPrimaryButton(
                title: viewModel.isLoading ? "Giriş yapılıyor…" : "Giriş Yap",
                isLoading: viewModel.isLoading
            ) {
                Task {
                    await viewModel.login()
                    if viewModel.errorMessage != nil { showError = true }
                }
            }
            .padding(.top, 4)

            Text("Hesabın yok mu?")
                .font(.system(size: 13))
                .foregroundStyle(InkMockup.captionColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)

            InkMockSecondaryButton(title: "Kaydol") {
                path.append(AuthRoute.register)
            }

            Button("Giriş yapmakta sorun mu yaşıyorsun?") {
                path.append(AuthRoute.problem)
            }
            .font(.system(size: 13))
            .underline()
            .foregroundStyle(InkMockup.captionColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 36)
        }
        .inkImageBackground("image-background")
        .alert("Giriş başarısız", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
