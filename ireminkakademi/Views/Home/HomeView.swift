import SwiftUI

struct HomeView: View {
    let container: DIContainer
    var hidesTabBar: Binding<Bool> = .constant(false)
    @State private var catalog = CatalogService()
    @State private var data: CatalogResponse?
    @State private var homework: [HomeworkAssignmentDTO] = []
    @State private var badgeProgress: BadgeProgressResponse?
    @State private var gamePlayedToday = DailyGameStore.playedToday
    @State private var latestPost: FeedPostDTO?

    var user: User? { container.sessionUser }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Bugünün Görevi")
                        if let next = data?.nextVideo {
                            NavigationLink {
                                VideoPlayerScreen(video: next, reportsProgress: user?.role == .student)
                                    .onAppear { hidesTabBar.wrappedValue = true }
                                    .onDisappear { Task { await loadHome() } }
                            } label: {
                                TodayContinueWatchingCard(video: next)
                            }
                            .buttonStyle(.plain)
                        } else {
                            InkMockCard {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "play.rectangle.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(InkMockup.accentPink)
                                        .padding(.top, 1)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Yeni videolar yakında")
                                            .font(AppTypography.cardTitle())
                                            .foregroundStyle(InkMockup.textPrimary)
                                        if user?.canSeeHomework == true {
                                            Text(homework.first?.title ?? "Bekleyen ödevin yok")
                                                .font(AppTypography.body())
                                                .foregroundStyle(InkMockup.captionColor)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }

                    NavigationLink {
                        CommunityFeedView(container: container, hidesTabBar: hidesTabBar)
                    } label: {
                        CommunityHomePreview(post: latestPost)
                    }
                    .buttonStyle(.plain)
                    .onAppear { Task { await loadLatestPost() } }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Günün Oyunu")
                        if gamePlayedToday {
                            InkMockCard {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(InkMockup.accentPink)
                                        .padding(.top, 1)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Bugün oynadın")
                                            .font(AppTypography.cardTitle(size: 19))
                                            .foregroundStyle(InkMockup.textPrimary)
                                        Text("Yarın tekrar gel. Günde bir kez oynanır.")
                                            .font(AppTypography.body())
                                            .foregroundStyle(InkMockup.captionColor)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                        } else {
                            NavigationLink {
                                HiddenObjectGame(hidesTabBar: hidesTabBar) { _ in
                                    Task { await reportWeeklyGame() }
                                }
                            } label: {
                                InkMockCard {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image("HomeGameIcon")
                                            .resizable()
                                            .renderingMode(.original)
                                            .scaledToFit()
                                            .frame(width: 44, height: 44)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Oyuna Başla")
                                                .font(AppTypography.cardTitle(size: 19))
                                                .foregroundStyle(InkMockup.textPrimary)
                                            Text("XP kazanmak için oyna. Günde bir kez.")
                                                .font(AppTypography.body())
                                                .foregroundStyle(InkMockup.captionColor)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(InkMockup.captionColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                }
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .studentScreenBackground()
            .navigationBarHidden(true)
            .task { await loadHome() }
            .onAppear { hidesTabBar.wrappedValue = false }
        }
    }

    private func loadHome() async {
        data = try? await catalog.fetchCatalog()
        if user?.canSeeHomework == true {
            homework = (try? await catalog.fetchHomework()) ?? []
        } else {
            homework = []
        }
        badgeProgress = try? await catalog.fetchBadgeProgress()
        gamePlayedToday = badgeProgress?.gamePlayedToday == true || DailyGameStore.playedToday
        await loadLatestPost()
    }

    private func loadLatestPost() async {
        latestPost = try? await CommunityFeedService().latest()
    }

    private func reportWeeklyGame() async {
        badgeProgress = try? await catalog.completeWeeklyGame()
        gamePlayedToday = true
        DailyGameStore.markPlayedToday()
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.sectionHeading(size: 24))
            .tracking(AppTypography.tracking(forDisplaySize: 24))
            .foregroundStyle(InkMockup.textPrimary)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ProfileAvatarView(
                url: user?.profilePhotoURL,
                initials: user?.initials ?? "",
                size: 56,
                frame: user?.avatarFrame ?? .gray,
                rank: user?.showsStudentRank == true
                    ? (badgeProgress.map { LevelMath.from(xp: $0.totalXp) } ?? user?.levelProgress)?.rank
                    : nil
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text("Hoş geldin, \(user?.firstName ?? "user_name")")
                        .font(AppTypography.cardTitle(size: 20))
                        .foregroundStyle(InkMockup.textPrimary)
                    if user?.isVerified == true {
                        VerifiedSeal(size: 14)
                    }
                }
                if user?.showsStudentRank == true {
                    Text((badgeProgress.map { LevelMath.from(xp: $0.totalXp) } ?? user?.levelProgress)?.caption ?? "Seviye 0  ·  0 XP")
                        .font(AppTypography.mono(size: 12))
                        .tracking(1.0)
                        .foregroundStyle(InkMockup.captionColor)
                    if let next = badgeProgress.map({ LevelMath.from(xp: $0.totalXp) }) ?? user?.levelProgress {
                        Text(next.nextCaption)
                            .font(AppTypography.mono(size: 11))
                            .tracking(0.8)
                            .foregroundStyle(InkMockup.placeholderColor)
                    }
                } else if user?.role == .crew {
                    Text("Ink Akademi Crew")
                        .font(AppTypography.mono(size: 12))
                        .tracking(1.0)
                        .foregroundStyle(InkMockup.accentPink)
                }
            }

            Spacer()

            NavigationLink {
                ChatView(container: container)
                    .onAppear { hidesTabBar.wrappedValue = true }
                    .onDisappear { hidesTabBar.wrappedValue = false }
            } label: {
                HomeChatBalloon(size: 62)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel("Sohbet")
        }
    }
}

/// Assetin etrafındaki boş siyah kenarı kırpar; balon başlıktaki yuvayı doldurur.
struct HomeChatBalloon: View {
    var size: CGFloat = 62

    var body: some View {
        Image("HomeChatIcon")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .scaleEffect(1.78)
            .frame(width: size, height: size)
            .clipped()
    }
}

private struct TodayContinueWatchingCard: View {
    let video: VideoDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                thumbnail
                LinearGradient(
                    colors: [.clear, .black.opacity(0.45)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.leading, 2)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.38), in: Circle())
                VStack {
                    Spacer()
                    if video.hasResumeProgress {
                        progressBar
                    }
                }
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(video.title)
                    .font(AppTypography.cardTitle(size: 18))
                    .foregroundStyle(InkMockup.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let contextLabel = video.contextLabel {
                    Text(contextLabel)
                        .font(AppTypography.body(size: 14))
                        .foregroundStyle(InkMockup.captionColor)
                        .lineLimit(1)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassChrome(radius: 22)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var thumbnail: some View {
        ZStack {
            Color.black
            if let url = video.thumbnailURL {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var placeholder: some View {
        ZStack {
            InkGlass.burgundy.opacity(0.35)
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.55))
                Capsule()
                    .fill(InkMockup.accentPink)
                    .frame(width: max(6, geo.size.width * video.progressFraction))
            }
        }
        .frame(height: 3)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private var accessibilityLabel: String {
        let watched = Int((video.progressFraction * 100).rounded())
        if video.hasResumeProgress {
            return "\(video.title), kaldığın yerden devam, yüzde \(watched) izlendi"
        }
        return video.title
    }
}
