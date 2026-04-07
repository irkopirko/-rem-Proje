import SwiftUI

struct ForgotPasswordView: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                if viewModel.resetEmailSent {
                    successState
                } else {
                    formState
                }
            }
        }
        .background(Color.inkBackground)
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.clearFields()
        }
    }

    // MARK: - Form State

    private var formState: some View {
        VStack(spacing: 0) {

            // Icon
            ZStack {
                Circle()
                    .fill(Color.inkGoldSoft)
                    .frame(width: 76, height: 76)

                Image(systemName: "lock.rotation")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Color.inkGold)
            }
            .padding(.top, 48)
            .padding(.bottom, 20)

            // Header
            VStack(spacing: 10) {
                Text("Şifreni Sıfırla")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.inkBlack)

                Text("Kayıtlı e-posta adresini gir,\nsıfırlama bağlantısı gönderelim")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 36)

            // Email field
            InkTextField(
                title: "E-posta",
                text: $viewModel.email,
                icon: "envelope",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                errorMessage: viewModel.emailError
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .background(Color.inkSurface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.inkGold.opacity(0.12), lineWidth: 0.8)
            )
            .padding(.horizontal, 20)

            // Error banner
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

            // Send button
            InkButton(
                title: "Sıfırlama Bağlantısı Gönder",
                isLoading: viewModel.isLoading
            ) {
                Task { await viewModel.forgotPassword() }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)

            // Back link
            Button {
                dismiss()
            } label: {
                Text("Giriş ekranına dön")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.inkTextSecondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Success State

    private var successState: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            Image(systemName: "checkmark.circle")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(Color.inkSuccess)
                .padding(.bottom, 24)

            Text("Bağlantı Gönderildi")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.inkBlack)
                .padding(.bottom, 10)

            Text("Sıfırlama bağlantısı\n\(viewModel.email) adresine gönderildi.")
                .font(.subheadline)
                .foregroundStyle(Color.inkTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

            InkButton(title: "Giriş Ekranına Dön") {
                viewModel.clearFields()
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

#Preview("Form") {
    NavigationStack {
        ForgotPasswordView(viewModel: AuthViewModel(
            authService: MockAuthService(),
            router: AppRouter()
        ))
    }
}

#Preview("Success") {
    NavigationStack {
        ForgotPasswordView(viewModel: {
            let vm = AuthViewModel(authService: MockAuthService(), router: AppRouter())
            vm.email = "test@example.com"
            vm.resetEmailSent = true
            return vm
        }())
    }
}
