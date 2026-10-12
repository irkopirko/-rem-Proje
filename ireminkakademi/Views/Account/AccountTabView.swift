import SwiftUI

struct AccountTabView: View {
    let container: DIContainer
    @State private var confirmLogout = false
    @State private var appearance = AppearanceSettings.shared
    @State private var catalog = CatalogService()
    @State private var badgeProgress: BadgeProgressResponse?
    @State private var selectedBadge: BadgeDTO?

    var user: User? { container.sessionUser }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    InkMockSectionTitle(text: "Hesabım")

                    profileSummary

                    Text("Rozetlerim")
                        .font(AppTypography.subheading(size: 16))
                        .foregroundStyle(InkMockup.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)

                    if let badges = badgeProgress?.badges, !badges.isEmpty {
                        BadgeCarouselView(badges: badges) { selectedBadge = $0 }
                    }

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

                    appearanceCard

                    InkMockMenuButton(title: "Gizlilik ve Koşullar") {
                        LegalInfoView()
                    }

                    Button("Çıkış Yap") { confirmLogout = true }
                        .font(AppTypography.button(size: 15))
                        .foregroundStyle(Color.inkError)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                    NavigationLink {
                        DeleteAccountView(container: container)
                    } label: {
                        Text("Hesabımı Sil")
                            .font(AppTypography.caption())
                            .underline()
                            .foregroundStyle(InkMockup.captionColor)
                            .frame(maxWidth: .infinity)
                    }

                    Text(AppLegalConfig.appVersionText)
                        .font(AppTypography.mono(size: 11))
                        .foregroundStyle(InkMockup.captionColor)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .studentScreenBackground()
            .navigationBarHidden(true)
            .task { badgeProgress = try? await catalog.fetchBadgeProgress() }
            .overlay {
                if let selectedBadge {
                    BadgeInfoPopup(badge: selectedBadge) { self.selectedBadge = nil }
                }
            }
            .confirmationDialog("Çıkış yapmak istediğine emin misin?", isPresented: $confirmLogout, titleVisibility: .visible) {
                Button("Çıkış Yap", role: .destructive) {
                    Task { await container.completeLogout() }
                }
                Button("Vazgeç", role: .cancel) {}
            }
        }
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Görünüm")
                .font(AppTypography.cardTitle())
                .foregroundStyle(InkMockup.textPrimary)
            HStack(spacing: 10) {
                appearanceChip(title: "Aydınlık", isDark: false)
                appearanceChip(title: "Karanlık", isDark: true)
            }
        }
        .padding(16)
        .glassChrome(radius: 22)
    }

    private func appearanceChip(title: String, isDark: Bool) -> some View {
        Button {
            appearance.isDark = isDark
        } label: {
            Text(title)
                .font(AppTypography.button(size: 15))
                .foregroundStyle(appearance.isDark == isDark ? Color.white : InkMockup.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background {
                    if appearance.isDark == isDark {
                        Capsule().fill(InkGlass.rose)
                    } else {
                        Capsule().fill(InkGlass.surface.opacity(0.5))
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(appearance.isDark == isDark ? .isSelected : [])
    }

    private var profileSummary: some View {
        HStack(alignment: .top, spacing: 16) {
            EditableProfileAvatar(container: container, size: 84)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(user?.displayName ?? "")
                        .font(AppTypography.cardTitle(size: 20))
                        .foregroundStyle(InkMockup.textPrimary)
                    if user?.isVerified == true {
                        VerifiedSeal(size: 15)
                    }
                }
                if let username = user?.username {
                    Text("@\(username)")
                        .font(AppTypography.profileLabel())
                        .foregroundStyle(InkMockup.captionColor)
                }
                if let status = user?.membershipStatus {
                    Text(status.displayName)
                        .font(AppTypography.monoMedium(size: 11))
                        .tracking(0.8)
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

                Text("Bu bilgiler güvenliğin için değiştirilemez. Bir yanlışlık varsa \"Bize Ulaş\" üzerinden bize yazabilirsin.")
                    .font(AppTypography.caption(size: 12))
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
                .font(AppTypography.profileLabel(size: 13))
                .foregroundStyle(InkMockup.captionColor)
            HStack {
                Text(value ?? "—")
                    .font(AppTypography.body(size: 16))
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
            .glassChrome(radius: 16)
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
                    .font(AppTypography.body(size: 14))
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
        case .trial: return "Deneme üyeliğin aktif. Ink Akademi'nin deneme sürümüne açtığı videoları izleyebilirsin. Ödevler abonelikle açılır."
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
                    .font(AppTypography.sectionHeading())
                    .foregroundStyle(InkMockup.textPrimary)
                Text("Hesabını sildiğinde eğitim ilerlemen, rozetlerin, ödevlerin ve mesajların kalıcı olarak silinir. Bu işlem geri alınamaz.")
                    .font(AppTypography.body(size: 14))
                    .foregroundStyle(InkMockup.captionColor)
                    .fixedSize(horizontal: false, vertical: true)

                InkMockTextField(placeholder: "Şifren", text: $password, isSecure: true, textContentType: .password)

                if let errorMessage {
                    Text(errorMessage).font(AppTypography.caption()).foregroundStyle(Color.inkError)
                }

                Button {
                    confirm = true
                } label: {
                    Text(isLoading ? "Siliniyor…" : "Hesabımı Kalıcı Olarak Sil")
                        .font(AppTypography.button())
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
