import SwiftUI

struct HomeView: View {
    let container: DIContainer
    @State private var catalog = CatalogService()
    @State private var data: CatalogResponse?
    @State private var homework: [HomeworkAssignmentDTO] = []
    @State private var badgeProgress: BadgeProgressResponse?
    @State private var selectedBadge: BadgeDTO?

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
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(InkMockup.textPrimary)
                                            .multilineTextAlignment(.leading)
                                        if user?.canSeeHomework == true {
                                            Text(homework.first?.title ?? "Bekleyen ödevin yok")
                                                .font(.system(size: 15))
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
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(InkMockup.cardFill)
                                                .frame(width: 92, height: 92)
                                                .overlay {
                                                    if let url = badge.imageURL {
                                                        AsyncImage(url: url) { image in
                                                            image.resizable().scaledToFit().padding(10)
                                                        } placeholder: {
                                                            Image(systemName: badge.symbolName)
                                                                .font(.system(size: 30))
                                                        }
                                                    } else {
                                                        Image(systemName: badge.symbolName)
                                                            .font(.system(size: 30))
                                                    }
                                                }
                                                .foregroundStyle(badge.isEarned ? InkMockup.accentPink : InkMockup.placeholderColor)
                                                .opacity(badge.isEarned ? 1 : 0.45)
                                            Text(badge.title)
                                                .font(.system(size: 12, weight: .medium))
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
                        sectionTitle("Haftalık Oyun")
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
                                            .font(.system(size: 19, weight: .bold))
                                            .foregroundStyle(InkMockup.textPrimary)
                                        Text("XP kazanmak için oyna")
                                            .font(.system(size: 15))
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

                    if user?.canSeeHomework == true {
                        NavigationLink {
                            GuidePDFScreen()
                        } label: {
                            HStack {
                                Text("INK AKADEMI Rehberin")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(InkMockup.accentPink)
                            .padding(.horizontal, 18)
                            .frame(minHeight: 60)
                            .background(InkMockup.cardFill.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
    }

    private func reportWeeklyGame() async {
        badgeProgress = try? await catalog.completeWeeklyGame()
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .bold))
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
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(InkMockup.textPrimary)
                Text((badgeProgress.map { LevelMath.from(xp: $0.totalXp) } ?? user?.levelProgress)?.caption ?? "Seviye 0  ·  0 XP")
                    .font(.system(size: 13))
                    .foregroundStyle(InkMockup.captionColor)
                if let next = badgeProgress.map({ LevelMath.from(xp: $0.totalXp) }) ?? user?.levelProgress {
                    Text(next.nextCaption)
                        .font(.system(size: 11))
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
                Image(systemName: badge.symbolName)
                    .font(.system(size: 34))
                    .foregroundStyle(badge.isEarned ? InkMockup.accentPink : InkMockup.placeholderColor)
                    .frame(width: 72, height: 72)
                    .background(InkMockup.cardFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(badge.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(InkMockup.textPrimary)
                    .multilineTextAlignment(.center)

                Text(howToEarn)
                    .font(.system(size: 14))
                    .foregroundStyle(InkMockup.captionColor)
                    .multilineTextAlignment(.center)

                Text("+\(badge.xpReward) XP · \(badge.isEarned ? "Kazanıldı" : "Henüz kazanılmadı")")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(InkMockup.accentPink)

                Button("Tamam", action: onDismiss)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(InkMockup.accentPink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(22)
            .frame(maxWidth: 320)
            .background(Color(red: 0.12, green: 0.08, blue: 0.11))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(InkMockup.accentPink.opacity(0.28), lineWidth: 1)
            )
            .padding(.horizontal, 36)
        }
        .preferredColorScheme(.dark)
    }

    private var howToEarn: String {
        let text = badge.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? "Bu rozeti tamamlayınca kazanırsın." : text
    }
}
