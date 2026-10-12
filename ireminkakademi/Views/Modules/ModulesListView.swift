import SwiftUI

struct ModulesListView: View {
    let container: DIContainer
    var hidesTabBar: Binding<Bool> = .constant(false)
    @State private var catalog = CatalogService()
    @State private var data: CatalogResponse?
    @State private var programs: [EducationProgramDTO] = []
    @State private var loadError: String?
    @State private var isLoading = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    InkMockSectionTitle(text: "Eğitimler")

                    if container.sessionUser?.canSeeHomework == true {
                        NavigationLink {
                            GuidePDFScreen()
                        } label: {
                            AcademyGuideRow(locked: false)
                        }
                        .buttonStyle(.plain)
                    } else if container.sessionUser?.role == .student {
                        Button { showPaywall = true } label: {
                            AcademyGuideRow(locked: true)
                        }
                        .buttonStyle(.plain)
                    }

                    if let live = data?.liveSession, let url = URL(string: live.streamUrl) {
                        Link(destination: url) {
                            HStack(spacing: 12) {
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    .font(.system(size: 26))
                                    .foregroundStyle(InkMockup.accentPink)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Canlı Yayın")
                                        .font(AppTypography.monoMedium(size: 11))
                                        .tracking(1.0)
                                        .foregroundStyle(InkMockup.accentPink)
                                    Text(live.title)
                                        .font(AppTypography.cardTitle())
                                        .foregroundStyle(InkMockup.textPrimary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(InkMockup.captionColor)
                            }
                            .padding(16)
                            .glassChrome()
                        }
                    }

                    if let next = data?.nextVideo {
                        NavigationLink(value: next) {
                            ContinueWatchingCard(video: next)
                        }
                        .buttonStyle(.plain)
                    }

                    InkMockSubheading(text: programs.isEmpty ? "Modüller" : "Eğitim programları")

                    if !programs.isEmpty {
                        ForEach(programs) { program in
                            NavigationLink(value: program) {
                                EducationProgramCard(program: program)
                            }
                            .buttonStyle(.plain)
                        }
                    } else if let modules = data?.modules {
                        if modules.isEmpty {
                            emptyState("Henüz yayınlanmış eğitim yok.")
                        }
                        ForEach(modules) { module in
                            NavigationLink(value: module) {
                                ModuleCard(module: module)
                            }
                            .buttonStyle(.plain)
                        }
                    } else if let loadError {
                        emptyState(loadError)
                    } else {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                    }
                }
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .studentScreenBackground()
            .refreshable { await load() }
            .navigationDestination(for: EducationProgramDTO.self) { program in
                EducationProgramDetailView(program: program, container: container, hidesTabBar: hidesTabBar)
            }
            .navigationDestination(for: ModuleDTO.self) { module in
                ModuleDetailView(module: module, container: container, hidesTabBar: hidesTabBar)
            }
            .navigationDestination(for: VideoDTO.self) { video in
                VideoPlayerScreen(video: video, reportsProgress: container.sessionUser?.role == .student)
                    .onAppear { hidesTabBar.wrappedValue = true }
            }
            .task { if data == nil { await load() } }
            .onAppear { hidesTabBar.wrappedValue = false }
            .overlay {
                if showPaywall {
                    ZStack {
                        Color.black.opacity(0.55).ignoresSafeArea().onTapGesture { showPaywall = false }
                        MembershipPaywallSheet { showPaywall = false }
                    }
                }
            }
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let catalogTask = catalog.fetchCatalog()
            async let programsTask = catalog.fetchPrograms()
            data = try await catalogTask
            programs = (try? await programsTask) ?? []
            loadError = nil
        } catch {
            if data == nil && programs.isEmpty { loadError = error.localizedDescription }
        }
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.body())
            .foregroundStyle(InkMockup.captionColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
    }
}

struct EducationProgramCard: View {
    let program: EducationProgramDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if program.coverURL != nil {
                ProductImageView(url: program.coverURL)
                    .frame(maxWidth: .infinity)
                    .frame(height: 128)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            HStack(spacing: 14) {
                Text(program.numberLabel)
                    .font(AppTypography.monoMedium(size: 13))
                    .tracking(0.8)
                    .foregroundStyle(InkMockup.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(InkGlass.burgundy.opacity(0.7)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.title)
                        .font(AppTypography.cardTitle())
                        .foregroundStyle(InkMockup.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(program.subtitle)
                        .font(AppTypography.caption())
                        .foregroundStyle(InkMockup.captionColor)
                    if let instructor = program.instructorName, !instructor.isEmpty {
                        Text(instructor)
                            .font(AppTypography.monoMedium(size: 11))
                            .foregroundStyle(InkMockup.accentPink)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(InkMockup.captionColor)
            }

            if let desc = program.description, !desc.isEmpty {
                Text(desc)
                    .font(AppTypography.body(size: 14))
                    .foregroundStyle(InkMockup.captionColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            if program.videoCount > 0 {
                ProgressView(value: Double(program.completedCount), total: Double(max(program.videoCount, 1)))
                    .tint(InkMockup.accentPink)
            }
        }
        .padding(16)
        .glassChrome()
    }
}

struct ModuleCard: View {
    let module: ModuleDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                Text(module.numberLabel)
                    .font(AppTypography.monoMedium(size: 13))
                    .tracking(0.8)
                    .foregroundStyle(InkMockup.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(InkGlass.burgundy.opacity(0.7)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(module.title)
                        .font(AppTypography.cardTitle())
                        .foregroundStyle(InkMockup.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(AppTypography.caption())
                        .foregroundStyle(InkMockup.captionColor)
                }
                Spacer(minLength: 0)
                if module.locked == true {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(InkMockup.captionColor)
                }
                Image(systemName: "chevron.right").foregroundStyle(InkMockup.captionColor)
            }

            if let desc = module.description, !desc.isEmpty {
                Text(desc)
                    .font(AppTypography.body(size: 14))
                    .foregroundStyle(InkMockup.captionColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            if module.videoCount > 0 {
                ProgressView(value: Double(module.completedCount), total: Double(module.videoCount))
                    .tint(InkMockup.accentPink)
            }
        }
        .padding(16)
        .glassChrome()
    }

    private var subtitle: String {
        guard module.videoCount > 0 else { return "Yakında" }
        return "\(module.videoCount) ders · \(module.completedCount) tamamlandı"
    }
}

private struct ContinueWatchingCard: View {
    let video: VideoDTO

    var body: some View {
        HStack(spacing: 14) {
            VideoThumbnail(url: video.thumbnailURL)
                .frame(width: 120, height: 68)
                .overlay(Image(systemName: "play.fill").font(.system(size: 20)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 4) {
                Text("Sıradaki ders")
                    .font(AppTypography.monoMedium(size: 11))
                    .tracking(1.0)
                    .foregroundStyle(InkMockup.accentPink)
                Text(video.title)
                    .font(AppTypography.cardTitle(size: 17))
                    .foregroundStyle(InkMockup.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(video.durationLabel)
                    .font(AppTypography.mono(size: 11))
                    .foregroundStyle(InkMockup.captionColor)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .glassChrome()
    }
}
