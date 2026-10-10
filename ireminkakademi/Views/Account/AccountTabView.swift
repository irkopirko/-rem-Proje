import SwiftUI

struct AccountTabView: View {
    let container: DIContainer
    @State private var confirmLogout = false

    var user: User? { container.sessionUser }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    InkMockSectionTitle(text: "Hesabım")

                    profileSummary

                    InkMockMenuButton(title: "Kişisel Bilgiler") {
                        PersonalInfoView(user: user)
                    }

                    InkMockMenuButton(title: "Üyeliğim") {
                        MembershipInfoView(user: user)
                    }

                    InkMockMenuButton(title: "Şifremi Değiştir") {
                        ChangePasswordView(authService: container.authService)
                    }

                    InkMockMenuButton(title: "Bize Ulaş") {
                        ContactSupportView()
                    }

                    InkMockMenuButton(title: "Gizlilik ve Koşullar") {
                        LegalInfoView()
                    }

                    Button("Çıkış Yap") { confirmLogout = true }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.inkError)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                    NavigationLink {
                        DeleteAccountView(container: container)
                    } label: {
                        Text("Hesabımı Sil")
                            .font(.system(size: 13))
                            .underline()
                            .foregroundStyle(InkMockup.captionColor)
                            .frame(maxWidth: .infinity)
                    }

                    Text(AppLegalConfig.appVersionText)
                        .font(.system(size: 11))
                        .foregroundStyle(InkMockup.captionColor)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .studentScreenBackground()
            .navigationBarHidden(true)
            .confirmationDialog("Çıkış yapmak istediğine emin misin?", isPresented: $confirmLogout, titleVisibility: .visible) {
                Button("Çıkış Yap", role: .destructive) {
                    Task { await container.completeLogout() }
                }
                Button("Vazgeç", role: .cancel) {}
            }
        }
    }

    private var profileSummary: some View {
        HStack(spacing: 16) {
            EditableProfileAvatar(container: container, size: 84)
            VStack(alignment: .leading, spacing: 3) {
                Text(user?.displayName ?? "")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(InkMockup.textPrimary)
                if let username = user?.username {
                    Text("@\(username)")
                        .font(.system(size: 14))
                        .foregroundStyle(InkMockup.captionColor)
                }
                if let status = user?.membershipStatus {
                    Text(status.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(InkMockup.accentPink)
                }
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }
}

/// Kimlik bilgileri yalnızca görüntülenir; düzeltme için destek ekibine yazılır.
struct PersonalInfoView: View {
    let user: User?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                InkReadOnlyField(title: "Kullanıcı adı", value: user?.username.map { "@\($0)" })
                InkReadOnlyField(title: "İsim", value: user?.firstName)
                InkReadOnlyField(title: "Soyisim", value: user?.lastName)
                InkReadOnlyField(title: "Doğum tarihi", value: user?.formattedBirthDate)
                InkReadOnlyField(title: "E-mail", value: user?.email)
                if let userNo = user?.userNo {
                    InkReadOnlyField(title: "Üye numarası", value: "#\(userNo)")
                }

                Text("Bu bilgiler güvenliğin için değiştirilemez. Bir yanlışlık varsa \"Bize Ulaş\" üzerinden bize yazabilirsin.")
                    .font(.system(size: 12))
                    .foregroundStyle(InkMockup.captionColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            .padding(InkMockup.screenHorizontal)
        }
        .studentScreenBackground()
        .navigationTitle("Kişisel Bilgiler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InkReadOnlyField: View {
    let title: String
    let value: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(InkMockup.captionColor)
            HStack {
                Text(value ?? "—")
                    .font(.system(size: 16))
                    .foregroundStyle(InkMockup.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(InkMockup.placeholderColor)
            }
            .padding(.horizontal, 16)
            .frame(height: InkMockup.fieldHeight)
            .background(InkMockup.fieldFill.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(InkMockup.fieldBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Değiştirilemez")
    }
}

struct MembershipInfoView: View {
    let user: User?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                InkReadOnlyField(title: "Üyelik türü", value: user?.membershipStatus.displayName)
                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(InkMockup.captionColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(InkMockup.screenHorizontal)
        }
        .studentScreenBackground()
        .navigationTitle("Üyeliğim")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var description: String {
        switch user?.membershipStatus {
        case .trial: return "Deneme üyeliğin aktif. Ink Akademi Crew'un deneme sürümüne açtığı videoları izleyebilirsin. Ödevler abonelikle açılır."
        case .trialExpired: return "Deneme süren doldu. Eğitimlere devam etmek için üyeliğini yenileyebilirsin."
        case .plus, .lifePlus: return "Tüm eğitimlere, ödevlere ve canlı yayınlara erişimin var."
        case .light: return "Satın almış üyeler gibi eğitimlere ve ödevlere erişimin var."
        default: return "Aktif bir üyeliğin bulunmuyor."
        }
    }
}

struct LegalInfoView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                InkMockPrimaryButton(title: "Gizlilik Politikası") { openURL(AppLegalConfig.privacyPolicyURL) }
                InkMockSecondaryButton(title: "Kullanım Koşulları") { openURL(AppLegalConfig.termsOfUseURL) }
            }
            .padding(InkMockup.screenHorizontal)
        }
        .studentScreenBackground()
        .navigationTitle("Gizlilik ve Koşullar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DeleteAccountView: View {
    let container: DIContainer
    @State private var password = ""
    @State private var confirm = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Hesabını silmek üzeresin")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(InkMockup.textPrimary)
                Text("Hesabını sildiğinde eğitim ilerlemen, rozetlerin, ödevlerin ve mesajların kalıcı olarak silinir. Bu işlem geri alınamaz.")
                    .font(.system(size: 14))
                    .foregroundStyle(InkMockup.captionColor)
                    .fixedSize(horizontal: false, vertical: true)

                InkMockTextField(placeholder: "Şifren", text: $password, isSecure: true, textContentType: .password)

                if let errorMessage {
                    Text(errorMessage).font(.system(size: 13)).foregroundStyle(Color.inkError)
                }

                Button {
                    confirm = true
                } label: {
                    Text(isLoading ? "Siliniyor…" : "Hesabımı Kalıcı Olarak Sil")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: InkMockup.buttonHeight)
                        .background(Color.inkError, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(password.isEmpty || isLoading)
                .opacity(password.isEmpty ? 0.5 : 1)
            }
            .padding(InkMockup.screenHorizontal)
        }
        .studentScreenBackground()
        .navigationTitle("Hesabımı Sil")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Hesabın kalıcı olarak silinecek. Emin misin?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Evet, hesabımı sil", role: .destructive) {
                Task { await delete() }
            }
            Button("Vazgeç", role: .cancel) {}
        }
    }

    private func delete() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await container.authService.deleteAccount(password: password)
            await container.completeLogout()
        } catch InkAPIError.unauthorized {
            errorMessage = "Şifren yanlış."
        } catch LocalAuthError.invalidCredentials {
            errorMessage = "Şifren yanlış."
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}
