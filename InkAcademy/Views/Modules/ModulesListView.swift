import SwiftUI

struct ModulesListView: View {
    @Bindable var viewModel: ModulesViewModel
    @Bindable var accessManager: AccessManager
    @State private var scannedLesson: Lesson?
    @State private var selectedOffer: PaywallOffer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    headerCard

                    if let errorMessage = viewModel.errorMessage {
                        ErrorBannerView(message: errorMessage)
                    }

                    if !viewModel.unlockedModules.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            SectionHeaderView(text: "Eğitimler")

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ],
                                spacing: 14
                            ) {
                                ForEach(viewModel.unlockedModules) { module in
                                    NavigationLink(value: module) {
                                        ModuleCardView(module: module)
                                    }
                                    .buttonStyle(.plain)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                            .animation(.easeInOut(duration: 0.25), value: viewModel.unlockedModules.count)
                        }
                    }

                    if !viewModel.lockedModules.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            SectionHeaderView(text: "Kilitli Modüller")

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ],
                                spacing: 14
                            ) {
                                ForEach(viewModel.lockedModules) { module in
                                    Button {
                                        selectedOffer = accessManager.offer(for: module)
                                    } label: {
                                        ModuleCardView(module: module)
                                    }
                                    .buttonStyle(.plain)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                            .animation(.easeInOut(duration: 0.25), value: viewModel.lockedModules.count)
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
            .searchable(text: $viewModel.searchText, prompt: "Modül ara...")
            .navigationDestination(for: TrainingModule.self) { module in
                ModuleDetailView(
                    module: module,
                    moduleService: viewModel.moduleService,
                    assignmentService: viewModel.assignmentService
                )
            }
            .navigationDestination(item: $scannedLesson) { lesson in
                LessonDetailView(viewModel: LessonDetailViewModel(
                    lesson: lesson,
                    moduleService: viewModel.moduleService,
                    assignmentService: viewModel.assignmentService
                ))
            }
            .sheet(isPresented: $viewModel.showQRScanner) {
                QRScannerFlowView(
                    viewModel: QRScannerViewModel(qrService: viewModel.qrService),
                    onResolvedLesson: { lesson in
                        scannedLesson = lesson
                        viewModel.showQRScanner = false
                    }
                )
            }
            .sheet(item: $selectedOffer) { offer in
                PaywallView(offer: offer, accessManager: accessManager)
            }
            .task {
                await viewModel.loadModules()
            }
            .refreshable {
                await viewModel.loadModules()
            }
            .loadingOverlay(isLoading: viewModel.isLoading)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        AnimatedDashboardCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Öğrenme Haritası")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.inkTextPrimary)

                        Text("\(viewModel.modules.count) modül · \(viewModel.completedLessonsCount) ders tamamlandı")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.inkTextSecondary)

                        Text("Aktif plan: \(accessManager.currentTier.title)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.inkAccent)
                    }

                    Spacer()

                    learningMapArtwork
                }

                HStack(spacing: 16) {
                    AnimatedProgressRing(
                        progress: viewModel.overallProgress,
                        lineWidth: 5,
                        size: 52,
                        tintColor: .inkTeal
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Genel İlerleme")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.inkTextPrimary)

                        Text("\(viewModel.modules.flatMap(\.lessons).count) toplam ders")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.inkTextTertiary)
                    }

                    Spacer()
                }

                HStack(spacing: 10) {
                    summaryPill(title: "Açık", value: "\(viewModel.unlockedModules.count)", accent: .inkTeal)
                    summaryPill(title: "Kilitli", value: "\(viewModel.lockedModules.count)", accent: .inkRose)
                    summaryPill(title: "Tamamlanan", value: "\(viewModel.completedLessonsCount)", accent: .inkSage)
                }
            }
        }
    }

    private var learningMapArtwork: some View {
        HStack(spacing: 8) {
            VStack(spacing: 6) {
                roundedIcon(symbol: "sparkles", accent: .inkTeal)
                roundedIcon(symbol: "pencil.and.outline", accent: .inkRose)
            }

            VStack(spacing: 6) {
                Button {
                    viewModel.showQRScanner = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadii.lg, style: .continuous)
                            .fill(Color.inkIndigoSoft)
                            .frame(width: 62, height: 62)

                        RoundedRectangle(cornerRadius: AppRadii.lg, style: .continuous)
                            .stroke(Color.inkIndigo.opacity(0.15), lineWidth: 1)
                            .frame(width: 62, height: 62)

                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Color.inkIndigo)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func roundedIcon(symbol: String, accent: Color) -> some View {
        RoundedRectangle(cornerRadius: AppRadii.sm, style: .continuous)
            .fill(accent.opacity(0.1))
            .frame(width: 38, height: 38)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
            }
    }

    private func summaryPill(title: String, value: String, accent: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkTextPrimary)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.inkTextTertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.inkSurfaceSecondary)
        .clipShape(Capsule())
    }
}

#Preview {
    ModulesListView(
        viewModel: ModulesViewModel(
            moduleService: MockModuleService(),
            qrService: MockQRService(),
            assignmentService: MockAssignmentService(),
            accessManager: AccessManager()
        ),
        accessManager: AccessManager()
    )
}