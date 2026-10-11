import SwiftUI

struct HomeView: View {
    let container: DIContainer
    @State private var catalog = CatalogService()
    @State private var data: CatalogResponse?
    @State private var homework: [HomeworkAssignmentDTO] = []
    @State private var badgeProgress: BadgeProgressResponse?
    @State private var selectedBadge: BadgeDTO?
    @State private var gamePlayedToday = DailyGameStore.playedToday

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
                                HStack(spacing: 14) {
                                    Image(systemName: "play.rectangle.fill")
                                        .font(.system(size: 34))
                                        .foregroundStyle(InkMockup.accentPink)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(data?.nextVideo?.title ?? "Yeni videolar yakında")
                                            .font(AppTypography.cardTitle())
                                            .foregroundStyle(InkMockup.textPrimary)
                                            .multilineTextAlignment(.leading)
                                        if user?.canSeeHomework == true {
                                            Text(homework.first?.title ?? "Bekleyen ödevin yok")
                                                .font(AppTypography.body())
                                                .foregroundStyle(InkMockup.captionColor)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                    if data?.nextVideo != nil {
                                        Image(systemName: "chevron.right").foregroundStyle(InkMockup.captionColor)
                                    }
                                }
                                .padding(.vertical, 10)
                                .frame(minHeight: 110)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(data?.nextVideo == nil)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Rozetler")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(badgeProgress?.badges ?? []) { badge in
                                    Button { selectedBadge = badge } label: {
                                        VStack(spacing: 8) {
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(.clear)
                                                .frame(width: 92, height: 92)
                                                .overlay { BadgeGlyph(badge: badge, size: 30) }
                                                .glassChrome(radius: 18)
                                            Text(badge.title)
                                                .font(AppTypography.caption(size: 12))
                                                .foregroundStyle(InkMockup.captionColor)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                                .frame(width: 92)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(badge.title), \(badge.xpReward) XP\(badge.isEarned ? ", kazanıldı" : "")")
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Günün Oyunu")
                        if gamePlayedToday {
                            InkMockCard {
                                HStack(spacing: 14) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(InkMockup.accentPink)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Bugün oynadın")
                                            .font(AppTypography.cardTitle(size: 19))
                                            .foregroundStyle(InkMockup.textPrimary)
                                        Text("Yarın tekrar gel. Günde bir kez oynanır.")
                                            .font(AppTypography.body())
                                            .foregroundStyle(InkMockup.captionColor)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 10)
                                .frame(minHeight: 100)
                            }
                        } else {
                            NavigationLink {
                                HiddenObjectGame { _ in
                                    Task { await reportWeeklyGame() }
                                }
                            } label: {
                                InkMockCard {
                                    HStack(spacing: 14) {
                                        Image(systemName: "gamecontroller.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(InkMockup.accentPink)
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Oyuna Başla")
                                                .font(AppTypography.cardTitle(size: 19))
                                                .foregroundStyle(InkMockup.textPrimary)
                                            Text("XP kazanmak için oyna. Günde bir kez.")
                                                .font(AppTypography.body())
                                                .foregroundStyle(InkMockup.captionColor)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(InkMockup.captionColor)
                                    }
                                    .padding(.vertical, 10)
                                    .frame(minHeight: 100)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if user?.canSeeHomework == true {
                        NavigationLink {
                            GuidePDFScreen()
                        } label: {
                            HStack {
                                Text("INK AKADEMI Rehberin")
                                    .font(AppTypography.cardTitle(size: 17))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(InkMockup.textPrimary)
                            .padding(.horizontal, 18)
                            .frame(minHeight: 60)
                            .glassChrome(radius: 18, emphasized: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .studentScreenBackground()
            .navigationBarHidden(true)
            .task { await loadHome() }
            .overlay {
                if let badge = selectedBadge {
                    BadgeInfoPopup(badge: badge) { selectedBadge = nil }
                }
            }
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
                rank: (badgeProgress.map { LevelMath.from(xp: $0.totalXp) } ?? user?.levelProgress)?.rank
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("Hoş geldin, \(user?.firstName ?? "user_name")")
                    .font(AppTypography.cardTitle(size: 20))
                    .foregroundStyle(InkMockup.textPrimary)
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
            }

            Spacer()

            NavigationLink {
                ChatView(container: container)
            } label: {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(InkMockup.accentPink)
            }
        }
    }
}

private struct BadgeInfoPopup: View {
    let badge: BadgeDTO
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 14) {
                BadgeGlyph(badge: badge, size: 34)
                    .frame(width: 72, height: 72)
                    .glassChrome(radius: 16)

                Text(badge.title)
                    .font(AppTypography.cardTitle())
                    .foregroundStyle(InkMockup.textPrimary)
                    .multilineTextAlignment(.center)

                Text(howToEarn)
                    .font(AppTypography.body(size: 14))
                    .foregroundStyle(InkMockup.captionColor)
                    .multilineTextAlignment(.center)

                Text("+\(badge.xpReward) XP · \(badge.isEarned ? "Kazanıldı" : "Henüz kazanılmadı")")
                    .font(AppTypography.monoMedium(size: 12))
                    .tracking(1.1)
                    .foregroundStyle(InkMockup.accentPink)

                GlassButton(title: "Tamam", action: onDismiss)
            }
            .padding(22)
            .frame(maxWidth: 320)
            .glassChrome(radius: 24, emphasized: true)
            .padding(.horizontal, 36)
        }
    }

    private var howToEarn: String {
        let text = badge.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? "Bu rozeti tamamlayınca kazanırsın." : text
    }
}

struct BadgeGlyph: View {
    let badge: BadgeDTO
    var size: CGFloat = 30

    var body: some View {
        if let url = badge.imageURL {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit().padding(8)
            } placeholder: {
                fallback
            }
        } else if let name = badge.localImageName {
            Image(name).resizable().scaledToFit().padding(6)
        } else {
            fallback
        }
    }

    private var fallback: some View {
        Image(systemName: badge.symbolName)
            .font(.system(size: size))
            .foregroundStyle(badge.isEarned ? InkMockup.accentPink : InkMockup.placeholderColor)
    }
}
