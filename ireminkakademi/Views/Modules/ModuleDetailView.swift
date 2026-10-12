import SwiftUI

struct ModuleDetailView: View {
    let module: ModuleDTO
    let container: DIContainer
    var hidesTabBar: Binding<Bool> = .constant(false)
    @State private var catalog = CatalogService()
    @State private var videos: [VideoDTO]?
    @State private var loadError: String?
    @State private var showPaywall = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    Text(module.numberLabel)
                        .font(AppTypography.monoMedium(size: 13))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(InkGlass.burgundy.opacity(0.7)))
                    Text(module.title)
                        .font(AppTypography.sectionHeading())
                        .tracking(AppTypography.tracking(forDisplaySize: 26))
                        .foregroundStyle(InkMockup.textPrimary)
                }

                if let desc = module.description, !desc.isEmpty {
                    Text(desc)
                        .font(AppTypography.body())
                        .foregroundStyle(InkMockup.textPrimary.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 4)
                }

                if let videos {
                    if videos.isEmpty {
                        Text("Bu modülde henüz ders yok.")
                            .font(AppTypography.body())
                            .foregroundStyle(InkMockup.captionColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    }
                    ForEach(videos) { video in
                        if video.isLocked(for: container.sessionUser) {
                            Button { showPaywall = true } label: {
                                VideoRow(video: video, locked: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(value: video) {
                                VideoRow(video: video, locked: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else if let loadError {
                    Text(loadError)
                        .font(.system(size: 15))
                        .foregroundStyle(InkMockup.captionColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                } else {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 32)
                }
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .studentScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
        .onAppear { hidesTabBar.wrappedValue = true }
        .overlay {
            if showPaywall {
                ZStack {
                    Color.black.opacity(0.55).ignoresSafeArea().onTapGesture { showPaywall = false }
                    MembershipPaywallSheet { showPaywall = false }
                }
            }
        }
    }

    private func load() async {
        do {
            videos = try await catalog.fetchModuleVideos(moduleId: module.id)
            loadError = nil
        } catch {
            if videos == nil { loadError = error.localizedDescription }
        }
    }
}

private struct VideoRow: View {
    let video: VideoDTO
    var locked = false

    var body: some View {
        HStack(spacing: 12) {
            VideoThumbnail(url: video.thumbnailURL)
                .frame(width: 128, height: 72)
                .overlay { if locked { LockedContentOverlay() } }
                .overlay(alignment: .bottomTrailing) {
                    Text(video.durationLabel)
                        .font(AppTypography.monoMedium(size: 11))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 4))
                        .padding(5)
                }
                .overlay(alignment: .bottom) {
                    if video.progressFraction > 0 {
                        GeometryReader { geo in
                            Rectangle()
                                .fill(InkMockup.accentPink)
                                .frame(width: geo.size.width * video.progressFraction, height: 3)
                                .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text("Ders \(video.numberLabel)")
                    .font(AppTypography.monoMedium(size: 11))
                    .tracking(0.8)
                    .foregroundStyle(InkMockup.captionColor)
                Text(video.title)
                    .font(AppTypography.cardTitle(size: 17))
                    .foregroundStyle(InkMockup.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let desc = video.description, !desc.isEmpty {
                    Text(desc)
                        .font(AppTypography.body(size: 14))
                        .foregroundStyle(InkMockup.captionColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                HStack(spacing: 6) {
                    if let quality = video.qualityLabel {
                        Text(quality)
                            .font(AppTypography.mono(size: 10))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(InkMockup.captionColor, lineWidth: 1))
                            .foregroundStyle(InkMockup.captionColor)
                    }
                    if video.completed == true {
                        Label("Tamamlandı", systemImage: "checkmark.circle.fill")
                            .font(AppTypography.caption(size: 11))
                            .foregroundStyle(.green)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .glassChrome()
    }
}

/// CDN küçük resmi; `URLCache` sayesinde tekrar indirilmez.
struct VideoThumbnail: View {
    let url: URL?

    var body: some View {
        ZStack {
            Rectangle().fill(Color.black.opacity(0.85))
            if let url {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            } else {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
