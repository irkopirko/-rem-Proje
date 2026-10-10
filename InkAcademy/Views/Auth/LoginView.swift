import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var showRegister = false
    @State private var showForgotPassword = false
    @State private var didAppear = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // MARK: - Logo

                    VStack(spacing: 14) {
                        Image("InkAkademiLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300)

                        Text("Dövme Sanatı Eğitim Platformu")
                            .font(.subheadline)
                            .foregroundStyle(Color.inkTextSecondary)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 48)
                    .opacity(didAppear ? 1 : 0)
                    .scaleEffect(didAppear ? 1 : 0.98)
                    .animation(.easeInOut(duration: 0.35), value: didAppear)

                    // MARK: - Form

                    VStack(spacing: 18) {
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
                            errorMessage: viewModel.passwordError
                        )

                        // Forgot password link
                        HStack {
                            Spacer()
                            Button {
                                viewModel.clearFields()
                                showForgotPassword = true
                            } label: {
                                Text("Şifremi Unuttum")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.inkTextSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                    .background(Color.inkSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.inkBlack.opacity(0.08), lineWidth: 0.8)
                    )
                    .padding(.horizontal, 20)
                    .opacity(didAppear ? 1 : 0)
                    .offset(y: didAppear ? 0 : 8)
                    .animation(.easeInOut(duration: 0.3).delay(0.05), value: didAppear)

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
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // MARK: - Login button

                    InkButton(
                        title: "Giriş Yap",
                        isLoading: viewModel.isLoading,
                        accentColor: .inkAccent
                    ) {
                        Task { await viewModel.login() }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                    // MARK: - Demo hint

                    Text("Demo: iremcelikk2@hotmail.com / 123Remi*")
                        .font(.caption2)
                        .foregroundStyle(Color.inkTextTertiary)
                        .padding(.top, 12)

                    // MARK: - Divider

                    HStack {
                        Rectangle().fill(Color.inkDivider).frame(height: 0.5)
                        Text("veya")
                            .font(.caption)
                            .foregroundStyle(Color.inkTextTertiary)
                        Rectangle().fill(Color.inkDivider).frame(height: 0.5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                    // MARK: - Register button

                    InkButtonOutline(title: "Hesap Oluştur") {
                        viewModel.clearFields()
                        showRegister = true
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .inkPageBackground()
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(isPresented: $showRegister) {
                RegisterView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView(viewModel: viewModel)
            }
            .onAppear {
                didAppear = true
            }
        }
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel(
        authService: MockAuthService(),
        router: AppRouter()
    ))
}
