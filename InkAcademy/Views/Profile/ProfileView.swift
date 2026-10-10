import SwiftUI

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedBadge: Badge?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.sectionGap) {
                    headerCard

                    LevelCardView(
                        level: viewModel.progress.currentLevel,
                        xpText: viewModel.isOwnProfile ? viewModel.visibleXPText() : nil,
                        progress: viewModel.progress.progressToNextLevel,
                        remainingHint: viewModel.remainingXPHint(),
                        supplementalHint: viewModel.supplementalGateHint()
                    )

                    statsRow

                    quizRow

                    badgesSection

                    certificatesSection

                    instructorSection

                    demoActionsCard

                    logoutButton
                }
                .padding(.horizontal, AppSpacing.screenH)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xl)
            }
            .inkPageBackground()
            .navigationTitle("Profil")
            .sheet(item: $selectedBadge) { badge in
                BadgeDetailView(badge: badge)
            }
            .task {
                await viewModel.loadProfile()
            }
            .refreshable {
                await viewModel.loadProfile()
            }
            .loadingOverlay(isLoading: viewModel.isLoading)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.inkTeal, Color.inkIndigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 84, height: 84)
                Text(viewModel.initials)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(viewModel.userName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.inkTextPrimary)

            if !viewModel.email.isEmpty {
                Text(viewModel.email)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkTextTertiary)
            }

            Text(viewModel.levelDescription())
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.inkTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)

            Text(viewModel.progress.currentLevel.requirementText)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.inkTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.inkBorder.opacity(0.35), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.28 : 0.06), radius: 14, x: 0, y: 8)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            ProfileStatCardView(
                icon: "book.closed.fill",
                title: "Tamamlanan ders",
                value: "\(viewModel.progress.completedLessonIds.count)",
                tint: .inkTeal
            )
            ProfileStatCardView(
                icon: "square.stack.3d.up.fill",
                title: "Tamamlanan modül",
                value: "\(viewModel.progress.completedModuleIds.count)",
                tint: .inkAccent
            )
        }
    }

    private var quizRow: some View {
        ProfileStatCardView(
            icon: "checkmark.circle.trianglebadge.exclamationmark",
            title: "Sınav puanı (mock)",
            value: viewModel.quizAverageDisplay,
            tint: .inkIndigo
        )
    }

    // MARK: - Badges

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(text: "Rozetler")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.badges) { badge in
                        BadgeCardView(badge: badge) {
                            selectedBadge = badge
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Certificates

    private var certificatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(text: "Sertifikalar")
            VStack(spacing: 10) {
                ForEach(viewModel.certificates) { cert in
                    HStack {
                        Image(systemName: cert.isUnlocked ? "seal.fill" : "lock.fill")
                            .foregroundStyle(cert.isUnlocked ? Color.inkSage : Color.inkTextTertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cert.title)
                                .font(.subheadline.weight(.semibold))
                            Text(cert.level)
                                .font(.caption)
                                .foregroundStyle(Color.inkTextTertiary)
                        }
                        Spacer()
                        if cert.isUnlocked, let d = cert.issuedDate {
                            Text(d.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(Color.inkTextSecondary)
                        } else {
                            Text("Kilitli")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.inkWarning)
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var instructorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(text: "Eğitmen yorumu")
            Text(viewModel.instructorComment)
                .font(.subheadline)
                .foregroundStyle(Color.inkTextSecondary)
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Demo

    private var demoActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(text: "Demo — XP akışı")
            VStack(spacing: 10) {
                demoButton(title: "Ders Tamamla +XP", icon: "play.circle.fill") {
                    viewModel.completeDemoLesson()
                }
                demoButton(title: "Modül Tamamla +XP", icon: "checkmark.seal.fill") {
                    viewModel.completeDemoModule()
                }
                demoButton(title: "Rozet Kazan +XP", icon: "medal.fill") {
                    viewModel.earnDemoBadge()
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.inkBorder.opacity(0.35), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private func demoButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.inkTextTertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 50)
            .foregroundStyle(Color.inkTextPrimary)
            .background(Color.inkSurface.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logout

    private var logoutButton: some View {
        Button {
            Task { await viewModel.logout() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .medium))
                Text("Çıkış Yap")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(Color.inkError)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                    .stroke(Color.inkError.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }
}

#Preview("Kendi profili") {
    ProfileView(viewModel: ProfileViewModel(
        authService: MockAuthService(),
        router: AppRouter(),
        userProgress: UserProgressController(),
        ecosystem: MockEcosystemCatalogService()
    ))
}

#Preview("Başkasının profili") {
    ProfileView(viewModel: ProfileViewModel(
        authService: MockAuthService(),
        router: AppRouter(),
        userProgress: UserProgressController(),
        ecosystem: MockEcosystemCatalogService(),
        isOwnProfile: false
    ))
}
