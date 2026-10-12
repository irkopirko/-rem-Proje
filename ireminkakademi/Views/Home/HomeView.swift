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
                        NavigationLink {
                            if let next = data?.nextVideo {
                                VideoPlayerScreen(video: next, reportsProgress: user?.role == .student)
                            }
                        } label: {
                            InkMockCard {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "play.rectangle.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(InkMockup.accentPink)
                                        .padding(.top, 1)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(data?.nextVideo?.title ?? "Yeni videolar yakında")
                                            .font(AppTypography.cardTitle())
                                            .foregroundStyle(InkMockup.textPrimary)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                        if user?.canSeeHomework == true {
                                            Text(homework.first?.title ?? "Bekleyen ödevin yok")
                                                .font(AppTypography.body())
                                                .foregroundStyle(InkMockup.captionColor)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                    if data?.nextVideo != nil {
                                        Image(systemName: "chevron.right").foregroundStyle(InkMockup.captionColor)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(data?.nextVideo == nil)
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
                                HiddenObjectGame { _ in
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
                .padding(.bottom, 16)
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
                Image("HomeChatIcon")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
        }
    }
}
