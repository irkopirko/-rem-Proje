import SwiftUI

struct HomeView: View {
    let container: DIContainer
    @State private var catalog = CatalogService()
    @State private var data: CatalogResponse?
    @State private var homework: [HomeworkAssignmentDTO] = []

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
                                        Text(homework.first?.title ?? "Bekleyen ödevin yok")
                                            .font(.system(size: 15))
                                            .foregroundStyle(InkMockup.captionColor)
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
                                ForEach(0..<4, id: \.self) { _ in
                                    VStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(InkMockup.cardFill)
                                            .frame(width: 92, height: 92)
                                            .overlay(
                                                Image(systemName: "rosette")
                                                    .font(.system(size: 34))
                                                    .foregroundStyle(InkMockup.placeholderColor)
                                            )
                                        Text("rozet_name")
                                            .font(.system(size: 13))
                                            .foregroundStyle(InkMockup.captionColor)
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Haftalık Oyun")
                        NavigationLink {
                            HiddenObjectGame()
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

                    Button {} label: {
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
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .studentScreenBackground()
            .navigationBarHidden(true)
            .task {
                data = try? await catalog.fetchCatalog()
                homework = (try? await catalog.fetchHomework()) ?? []
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(InkMockup.textPrimary)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ProfileAvatarView(url: user?.profilePhotoURL, initials: user?.initials ?? "", size: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text("Hoş geldin, \(user?.firstName ?? "user_name")")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(InkMockup.textPrimary)
                Text("user_point_number")
                    .font(.system(size: 13))
                    .foregroundStyle(InkMockup.captionColor)
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
