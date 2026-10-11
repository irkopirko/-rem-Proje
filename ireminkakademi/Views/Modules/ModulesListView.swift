import SwiftUI

struct ModulesListView: View {
    let container: DIContainer
    @State private var catalog = CatalogService()
    @State private var data: CatalogResponse?
    @State private var loadError: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    InkMockSectionTitle(text: "Eğitimler")

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

                    InkMockSubheading(text: "Modüller")

                    if let modules = data?.modules {
                        if modules.isEmpty {
                            emptyState("Henüz yayınlanmış modül yok.")
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
                .padding(.bottom, 24)
            }
            .studentScreenBackground()
            .refreshable { await load() }
            .navigationDestination(for: ModuleDTO.self) { module in
                ModuleDetailView(module: module, container: container)
            }
            .navigationDestination(for: VideoDTO.self) { video in
                VideoPlayerScreen(video: video, reportsProgress: container.sessionUser?.role == .student)
            }
            .task { if data == nil { await load() } }
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            data = try await catalog.fetchCatalog()
            loadError = nil
        } catch {
            if data == nil { loadError = error.localizedDescription }
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

private struct ModuleCard: View {
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
