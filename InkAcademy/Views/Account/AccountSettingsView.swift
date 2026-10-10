import SwiftUI

struct AccountSettingsView: View {
    @Bindable var viewModel: AccountSettingsViewModel
    let authService: AuthServiceProtocol
    let profileViewModel: ProfileViewModel
    let userProgress: UserProgressController

    @State private var showDeleteConfirm = false
    @State private var showDeleteFinalConfirm = false

    var body: some View {
        NavigationStack {
            List {
                profileHeaderSection

                Section("Profil") {
                    NavigationLink {
                        PersonalInfoView(viewModel: viewModel)
                    } label: {
                        Label("Kişisel Bilgiler", systemImage: "person.text.rectangle")
                    }

                    NavigationLink {
                        ChangePasswordView(authService: authService)
                    } label: {
                        Label("Şifre Değiştir", systemImage: "key.fill")
                    }

                    NavigationLink {
                        ProfileView(viewModel: profileViewModel)
                    } label: {
                        Label("Rozetler ve seviye", systemImage: "medal.fill")
                    }
                }

                Section("İlerleme") {
                    progressRow(
                        title: "Tamamlanan modül",
                        value: "\(viewModel.completedModulesCount)",
                        icon: "square.stack.3d.up.fill"
                    )
                    progressRow(
                        title: "Tamamlanan ders",
                        value: "\(viewModel.completedLessonsCount)",
                        icon: "play.rectangle.fill"
                    )
                    progressRow(
                        title: "Bekleyen ödev",
                        value: "\(viewModel.pendingHomeworkCount)",
                        icon: "doc.badge.clock"
                    )
                    progressRow(
                        title: "Gönderilen ödev",
                        value: "\(viewModel.submittedHomeworkCount)",
                        icon: "paperplane.fill"
                    )

                    NavigationLink {
                        GamesListView(userProgress: userProgress)
                    } label: {
                        HStack {
                            Label("Haftalık seri ve oyunlar", systemImage: "flame.fill")
                            Spacer()
                            Text("\(viewModel.weeklyStreakDays) gün")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.inkAccent)
                        }
                    }
                }

                Section("Ayarlar") {
                    Toggle(isOn: Binding(
                        get: { viewModel.notificationPreferences.announcementsEnabled },
                        set: { viewModel.notificationPreferences.announcementsEnabled = $0 }
                    )) {
                        Label("Duyurular", systemImage: "megaphone.fill")
                    }

                    Toggle(isOn: Binding(
                        get: { viewModel.notificationPreferences.homeworkEnabled },
                        set: { viewModel.notificationPreferences.homeworkEnabled = $0 }
                    )) {
                        Label("Ödev bildirimleri", systemImage: "doc.text.fill")
                    }

                    Toggle(isOn: Binding(
                        get: { viewModel.notificationPreferences.messagesEnabled },
                        set: { viewModel.notificationPreferences.messagesEnabled = $0 }
                    )) {
                        Label("Mesajlar", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                }

                Section("Destek") {
                    if let helpURL = AppLegalConfig.helpCenterURL {
                        NavigationLink {
                            LegalDocumentView(title: "Yardım Merkezi", url: helpURL)
                        } label: {
                            Label("Yardım", systemImage: "questionmark.circle")
                        }
                    } else {
                        Label("Yardım", systemImage: "questionmark.circle")
                            .foregroundStyle(Color.inkTextSecondary)
                    }

                    NavigationLink {
                        ContactSupportView()
                    } label: {
                        Label("Bize ulaşın", systemImage: "envelope.fill")
                    }

                    NavigationLink {
                        LegalDocumentView(title: "Gizlilik Politikası", url: AppLegalConfig.privacyPolicyURL)
                    } label: {
                        Label("Gizlilik Politikası", systemImage: "hand.raised.fill")
                    }

                    NavigationLink {
                        LegalDocumentView(title: "Kullanım Koşulları", url: AppLegalConfig.termsOfUseURL)
                    } label: {
                        Label("Kullanım Koşulları", systemImage: "doc.plaintext")
                    }
                }

                Section("Hesap") {
                    Button(role: .destructive) {
                        Task { await viewModel.logout() }
                    } label: {
                        Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Hesabı Sil", systemImage: "trash.fill")
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        Text(AppLegalConfig.appVersionText)
                            .font(.caption)
                            .foregroundStyle(Color.inkTextTertiary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .inkPageBackground()
            .navigationTitle("Hesabım")
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .loadingOverlay(isLoading: viewModel.isLoading)
            .confirmationDialog(
                "Hesabını silmek istediğine emin misin?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Evet, devam et", role: .destructive) {
                    showDeleteFinalConfirm = true
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Bu işlem oturumunu kapatır ve hesabın silinmesi için talep oluşturur. Eğitim verilerin yönetici onayı olmadan kalıcı silinmeyebilir.")
            }
            .alert("Son onay", isPresented: $showDeleteFinalConfirm) {
                Button("Hesabımı sil", role: .destructive) {
                    Task { _ = await viewModel.deleteAccount() }
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                if let err = viewModel.deleteAccountError {
                    Text(err)
                } else {
                    Text("Bu adım geri alınamaz. Devam etmek istiyor musun?")
                }
            }
        }
    }

    @ViewBuilder
    private var profileHeaderSection: some View {
        Section {
            HStack(spacing: 16) {
                avatarView
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.userName.isEmpty ? "—" : viewModel.userName)
                        .font(.headline)
                        .foregroundStyle(Color.inkTextPrimary)
                    Text("@\(viewModel.username)")
                        .font(.subheadline)
                        .foregroundStyle(Color.inkTextSecondary)
                    Text(viewModel.email)
                        .font(.caption)
                        .foregroundStyle(Color.inkTextTertiary)
                }
            }
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let url = viewModel.avatarURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    initialsAvatar
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())
        } else {
            initialsAvatar
        }
    }

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.inkTeal, Color.inkIndigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(viewModel.initials)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 64, height: 64)
    }

    private func progressRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.inkTextSecondary)
        }
    }
}

#Preview {
    AccountSettingsView(
        viewModel: AccountSettingsViewModel(
            authService: MockAuthService(),
            router: AppRouter(),
            userProgress: UserProgressController(),
            assignmentService: MockAssignmentService()
        ),
        authService: MockAuthService(),
        profileViewModel: ProfileViewModel(
            authService: MockAuthService(),
            router: AppRouter(),
            userProgress: UserProgressController(),
            ecosystem: MockEcosystemCatalogService()
        ),
        userProgress: UserProgressController()
    )
}
