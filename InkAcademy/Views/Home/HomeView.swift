import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    let qrService: QRServiceProtocol
    @Bindable var accessManager: AccessManager

    @State private var showQRScanner = false
    @State private var selectedLesson: Lesson?
    @State private var selectedOffer: PaywallOffer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    headerSection

                    if let errorMessage = viewModel.errorMessage {
                        ErrorBannerView(message: errorMessage)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    AnimatedDashboardCard(delay: 0.02) {
                        todayTaskSection
                    }

                    if let offer = viewModel.recommendedOffer {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            SectionHeaderView(text: "Erişimini Yükselt")
                            upgradeSpotlightCard(offer: offer)
                        }
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        SectionHeaderView(text: "Rozet İlerlemesi")
                        badgeProgressSection
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        SectionHeaderView(text: "Hızlı Erişim")
                        quickAccessSection
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        SectionHeaderView(text: "Öne Çıkan Alanlar")
                        visualHighlightsSection
                    }

                    if let current = viewModel.currentLesson {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            SectionHeaderView(text: "Devam Eden Ders")
                            AnimatedDashboardCard(delay: 0.05) {
                                CurrentLessonCard(
                                    moduleName: current.module.title,
                                    lesson: current.lesson,
                                    moduleProgress: current.module.progressPercent,
                                    onTap: {
                                        selectedLesson = current.lesson
                                    }
                                )
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        SectionHeaderView(text: "Genel İlerleme")
                        AnimatedDashboardCard(delay: 0.12) {
                            progressSection
                        }
                    }

                    if let fb = viewModel.latestFeedback {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            SectionHeaderView(text: "Son Değerlendirme")
                            AnimatedDashboardCard(delay: 0.2) {
                                FeedbackPreviewCard(
                                    feedback: fb.feedback,
                                    assignmentTitle: fb.assignmentTitle
                                )
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        SectionHeaderView(text: "Canlı Dersler")
                        AnimatedDashboardCard(delay: 0.24) {
                            LiveLessonCard()
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screenH)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(Color.inkBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedLesson) { lesson in
                LessonDetailView(viewModel: viewModel.makeLessonDetailViewModel(for: lesson))
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .loadingOverlay(isLoading: viewModel.isLoading)
            .sheet(isPresented: $showQRScanner) {
                QRScannerFlowView(
                    viewModel: QRScannerViewModel(qrService: qrService),
                    onResolvedLesson: { lesson in
                        selectedLesson = lesson
                        showQRScanner = false
                    }
                )
            }
            .sheet(item: $selectedOffer) { offer in
                PaywallView(offer: offer, accessManager: accessManager)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.inkTeal, Color.inkIndigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Text(userInitials)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.user?.name ?? "Öğrenci")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.inkTextPrimary)

                HStack(spacing: 6) {
                    Text(viewModel.studentLevel)
                    Text("·")
                    Text(viewModel.currentTierTitle)
                    Text("·")
                    Text("XP: \(viewModel.experiencePoints)")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkTextSecondary)
            }

            Spacer()

            // Notification bell
            Button {} label: {
                Image(systemName: "bell")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.inkTextPrimary)
            }
            .buttonStyle(IconCircleButtonStyle(size: 44))
        }
    }

    // MARK: - Today Task

    private var todayTaskSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bugünün Görevi")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.inkTextPrimary)

                    Text(todaySubtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.inkTextSecondary)
                }

                Spacer()

                taskArtwork
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(todayChecklist, id: \.self) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.inkAccent)
                            .frame(width: 20, height: 20)
                            .background(Color.inkAccent.opacity(0.12))
                            .clipShape(Circle())

                        Text(item)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.inkTextPrimary)
                    }
                }
            }

            HStack {
                // Streak chip
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(dayStreak) gün seri")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Color.inkRose)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.inkRoseSoft)
                .clipShape(Capsule())

                Spacer()

                Button {
                    selectedLesson = viewModel.currentLesson?.lesson
                } label: {
                    Text("GÖREVE BAŞLA")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(Color.inkAccent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.currentLesson == nil)
            }
        }
    }

    // MARK: - Badge Progress

    private var badgeProgressSection: some View {
        HStack(spacing: 12) {
            DashboardStatCard(
                title: "Çizgi",
                value: "\(viewModel.completedLessons)",
                icon: "scribble.variable",
                subtitle: "/ \(max(viewModel.totalLessons, 1))",
                accentColor: .inkTeal
            )

            DashboardStatCard(
                title: "Açık",
                value: "\(viewModel.modules.count - viewModel.lockedModuleCount)",
                icon: "square.stack.3d.up.fill",
                subtitle: "modül",
                accentColor: .inkIndigo
            )

            DashboardStatCard(
                title: "Kilitli",
                value: "\(viewModel.lockedModuleCount)",
                icon: "lock.fill",
                subtitle: "yükseltme ile açılır",
                accentColor: .inkRose
            )
        }
    }

    // MARK: - Upgrade Spotlight Card

    private func upgradeSpotlightCard(offer: PaywallOffer) -> some View {
        Button {
            selectedOffer = offer
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(offer.eyebrow.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.inkAccent)
                            .tracking(0.5)

                        Text(offer.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.inkTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(offer.subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.inkTextSecondary)
                            .lineSpacing(2)
                    }

                    Spacer(minLength: 4)

                    upgradeArtwork
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(offer.primaryFeatures.prefix(3), id: \.self) { item in
                        FeatureRow(text: item)
                    }
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        if let original = offer.originalPrice {
                            Text(original)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.inkTextTertiary)
                                .strikethrough()
                        }

                        Text(offer.price)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.inkTextPrimary)
                    }

                    Spacer()

                    Text(offer.ctaTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.inkAccent)
                        .clipShape(Capsule())
                }
            }
            .padding(AppSpacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: AppRadii.xxl, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.inkSurface, Color.inkAccentSoft],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.xxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadii.xxl, style: .continuous)
                    .stroke(Color.inkAccent.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: AppShadows.elevatedRadius, x: 0, y: AppShadows.elevatedY)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Access

    private var quickAccessSection: some View {
        HStack(spacing: 12) {
            quickAccessCard(
                title: "QR Aç",
                subtitle: "Kod tara",
                icon: "qrcode.viewfinder",
                accent: .inkAccent,
                highlight: "Yeni"
            ) {
                showQRScanner = true
            }

            quickAccessCard(
                title: "Ödevler",
                subtitle: viewModel.pendingAssignmentCount > 0 ? "Teslim var" : "Hazır",
                icon: "doc.text.fill",
                accent: .inkIndigo,
                highlight: "\(viewModel.pendingAssignmentCount)"
            )

            quickAccessCard(
                title: "Yorumlar",
                subtitle: viewModel.latestFeedback == nil ? "Yeni yok" : "İncele",
                icon: "bubble.left.and.bubble.right.fill",
                accent: .inkTeal,
                highlight: viewModel.latestFeedback == nil ? nil : "Puan"
            )
        }
    }

    private var visualHighlightsSection: some View {
        HStack(spacing: 12) {
            visualHighlightCard(
                title: "Stüdyo Lab",
                subtitle: "Teknik tekrar alanı",
                accent: .inkRose,
                icon: "paintpalette.fill"
            )

            visualHighlightCard(
                title: "Akıllı Öneri",
                subtitle: smartSuggestionText,
                accent: .inkTeal,
                icon: "sparkles"
            )
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        HStack(spacing: 18) {
            AnimatedProgressRing(
                progress: viewModel.overallProgress,
                lineWidth: 7,
                size: 68,
                tintColor: .inkTeal
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Genel İlerleme")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkTextPrimary)

                Text("\(viewModel.completedLessons) / \(viewModel.totalLessons) ders tamamlandı")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkTextSecondary)

                Text("\(viewModel.completedModules) modül bitirildi")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkTextTertiary)
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private var userInitials: String {
        let parts = (viewModel.user?.name ?? "Öğrenci")
            .split(separator: " ")
            .prefix(2)
        let initials = parts.compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? "I" : initials
    }

    private var todaySubtitle: String {
        if let assignment = viewModel.nextPendingAssignment {
            let remaining = max(1, Calendar.current.dateComponents([.hour], from: .now, to: assignment.dueDate).hour ?? 0)
            return "Bugün bitir: \(remaining) saat kaldı"
        }
        return "\(greeting), öğrenme planın hazır"
    }

    private var todayChecklist: [String] {
        var items: [String] = []

        if let currentLesson = viewModel.currentLesson?.lesson {
            items.append("\(currentLesson.title) dersini sürdür")
        }

        if let assignment = viewModel.nextPendingAssignment {
            items.append("\(assignment.title) ödevini yükle")
        }

        items.append("Canlı ders akışını kontrol et")
        return Array(items.prefix(3))
    }

    private var dayStreak: Int {
        min(max(viewModel.completedLessons, 1), 30)
    }

    @ViewBuilder
    private func quickAccessCard(
        title: String,
        subtitle: String,
        icon: String,
        accent: Color,
        highlight: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        let content = VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadii.sm, style: .continuous)
                        .fill(accent.opacity(0.1))
                        .frame(width: 38, height: 38)

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                }

                Spacer()

                if let highlight {
                    Text(highlight)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accent.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkTextPrimary)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkTextTertiary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .padding(AppSpacing.md)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous)
                .stroke(Color.inkBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: AppShadows.softRadius, x: 0, y: AppShadows.softY)

        if let action {
            Button(action: action) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Günaydın"
        case 12..<18: return "İyi günler"
        default: return "İyi akşamlar"
        }
    }

    private var smartSuggestionText: String {
        if let lesson = viewModel.currentLesson?.lesson {
            return "\(lesson.title) ile devam et"
        }
        return "Yeni görevi aç"
    }

    private var taskArtwork: some View {
        ZStack {
            Circle()
                .fill(Color.inkIndigoSoft)
                .frame(width: 70, height: 70)

            Image(systemName: "hourglass")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.inkIndigo)
        }
    }

    private func visualHighlightCard(title: String, subtitle: String, accent: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                    .fill(accent.opacity(0.08))
                    .frame(height: 76)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(accent)
            }

            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.inkTextPrimary)

            Text(subtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.inkTextSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous)
                .stroke(Color.inkBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: AppShadows.softRadius, x: 0, y: AppShadows.softY)
    }

    private var upgradeArtwork: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: AppRadii.xl, style: .continuous)
                .fill(Color.inkTextPrimary.opacity(0.92))
                .frame(width: 110, height: 140)

            VStack(alignment: .leading, spacing: 6) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 6)

                Text("INK")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Text("ARTISTS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(14)

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.inkAccent.opacity(0.25))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkAccent)
                    }

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkAccent)
                    }
            }
            .padding(12)
        }
    }
}

#Preview {
    HomeView(
        viewModel: HomeViewModel(
            moduleService: MockModuleService(),
            authService: MockAuthService(),
            assignmentService: MockAssignmentService(),
            accessManager: AccessManager()
        ),
        qrService: MockQRService(),
        accessManager: AccessManager()
    )
}