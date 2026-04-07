import SwiftUI

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.sectionGap) {

                    // 1 — Avatar + Identity
                    avatarSection

                    // 2 — Progress Overview
                    progressCard

                    // 3 — Learning Stats
                    learningStatsCard

                    // 4 — Assignment Stats
                    assignmentStatsCard

                    // 5 — Logout
                    logoutButton
                }
                .padding(.horizontal, AppSpacing.screenH)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(Color.inkBackground)
            .navigationTitle("Profil")
            .task {
                await viewModel.loadProfile()
            }
            .refreshable {
                await viewModel.loadProfile()
            }
            .loadingOverlay(isLoading: viewModel.isLoading)
        }
    }

    // MARK: - 1. Avatar + Identity

    private var avatarSection: some View {
        VStack(spacing: 16) {
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

            Text(viewModel.displayName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.inkTextPrimary)

            if !viewModel.email.isEmpty {
                Text(viewModel.email)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkTextTertiary)
            }

            HStack(spacing: 6) {
                Image(systemName: viewModel.studentLevelIcon)
                    .font(.system(size: 11))
                Text(viewModel.studentLevel)
                    .font(.system(size: 12, weight: .bold))
                Text("·")
                    .font(.system(size: 12, weight: .bold))
                Text("XP \(viewModel.experiencePoints)")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Color.inkAccent)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color.inkAccentSoft)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - 2. Progress Overview

    private var progressCard: some View {
        HStack(spacing: 18) {
            AnimatedProgressRing(
                progress: viewModel.overallProgress,
                lineWidth: 6,
                size: 60,
                tintColor: .inkTeal
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Genel İlerleme")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkTextPrimary)

                Text("\(viewModel.completedLessons)/\(viewModel.totalLessons) ders tamamlandı")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkTextSecondary)

                Text("\(viewModel.completedModules) modül bitirildi")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkTextTertiary)
            }

            Spacer()
        }
        .padding(AppSpacing.lg)
        .premiumCard()
    }

    // MARK: - 3. Learning Stats

    private var learningStatsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeaderView(text: "Eğitim İstatistikleri")
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ProfileStatRow(
                    icon: "book.fill",
                    title: "Tamamlanan Modül",
                    value: "\(viewModel.completedModules)/\(viewModel.totalModules)",
                    iconColor: .inkTeal
                )

                rowDivider

                ProfileStatRow(
                    icon: "checkmark.circle",
                    title: "Tamamlanan Ders",
                    value: "\(viewModel.completedLessons)/\(viewModel.totalLessons)",
                    iconColor: .inkSage
                )

                rowDivider

                ProfileStatRow(
                    icon: "star.fill",
                    title: "Ortalama Puan",
                    value: viewModel.averageScoreFormatted,
                    iconColor: .inkAccent
                )
            }
            .padding(AppSpacing.md)
            .premiumCard()
        }
    }

    // MARK: - 4. Assignment Stats

    private var assignmentStatsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeaderView(text: "Ödev İstatistikleri")
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ProfileStatRow(
                    icon: "doc.text.fill",
                    title: "Toplam Ödev",
                    value: "\(viewModel.totalAssignments)",
                    iconColor: .inkIndigo
                )

                rowDivider

                ProfileStatRow(
                    icon: "arrow.up.doc",
                    title: "Gönderilen",
                    value: "\(viewModel.submittedAssignments)",
                    iconColor: .inkAccent
                )

                rowDivider

                ProfileStatRow(
                    icon: "checkmark.seal",
                    title: "Değerlendirilen",
                    value: "\(viewModel.reviewedAssignments)",
                    iconColor: .inkSage
                )
            }
            .padding(AppSpacing.md)
            .premiumCard()
        }
    }

    // MARK: - 5. Logout

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

    private var rowDivider: some View {
        Divider()
            .padding(.leading, 48)
    }
}

// MARK: - Preview

#Preview {
    ProfileView(viewModel: ProfileViewModel(
        authService: MockAuthService(),
        moduleService: MockModuleService(),
        assignmentService: MockAssignmentService(),
        router: AppRouter()
    ))
}