import SwiftUI

struct RegisterView: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: - Header

                VStack(spacing: 10) {
                    Text("Hesap Oluştur")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.inkBlack)

                    Text("Eğitime başlamak için bilgilerini gir")
                        .font(.subheadline)
                        .foregroundStyle(Color.inkTextSecondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 36)

                // MARK: - Form

                VStack(spacing: 18) {
                    InkTextField(
                        title: "Ad Soyad",
                        text: $viewModel.name,
                        icon: "person",
                        autocapitalization: .words,
                        errorMessage: viewModel.nameError
                    )

                    InkTextField(
                        title: "E-posta",
                        text: $viewModel.email,
                        icon: "envelope",
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        errorMessage: viewModel.emailError
                    )

                    InkSecureField(
                        title: "Şifre",
                        text: $viewModel.password,
                        icon: "lock",
                        textContentType: .newPassword,
                        errorMessage: viewModel.passwordError
                    )

                    InkSecureField(
                        title: "Şifre Tekrarı",
                        text: $viewModel.confirmPassword,
                        icon: "lock.rotation",
                        textContentType: .newPassword,
                        errorMessage: viewModel.confirmPasswordError
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(Color.inkSurface)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.inkGold.opacity(0.12), lineWidth: 0.8)
                )
                .padding(.horizontal, 20)

                // MARK: - Error banner

                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                    }
                    .foregroundStyle(Color.inkError)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .transition(.opacity)
                }

                // MARK: - Register button

                InkButton(
                    title: "Kayıt Ol",
                    isLoading: viewModel.isLoading
                ) {
                    Task { await viewModel.register() }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)

                // MARK: - Existing account link

                HStack(spacing: 4) {
                    Text("Zaten hesabın var mı?")
                        .foregroundStyle(Color.inkTextTertiary)
                    Button {
                        dismiss()
                    } label: {
                        Text("Giriş Yap")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.inkBlack)
                    }
                }
                .font(.caption)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.inkBackground)
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.clearFields()
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView(viewModel: AuthViewModel(
            authService: MockAuthService(),
            router: AppRouter()
        ))
    }
}
