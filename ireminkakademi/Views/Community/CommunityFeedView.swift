import SwiftUI

struct CommunityFeedView: View {
    let container: DIContainer
    var hidesTabBar: Binding<Bool> = .constant(false)

    @State private var feed = CommunityFeedService()
    @State private var posts: [FeedPostDTO] = []
    @State private var nextCursor: String?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var showCompose = false
    @State private var selectedAuthor: FeedAuthorDTO?
    @State private var selectedPost: FeedPostDTO?

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    InkMockSectionTitle(text: "Topluluk")
                    Spacer()
                    if container.sessionUser?.role == .crew {
                        NavigationLink {
                            CrewCommunityView(container: container)
                        } label: {
                            Text("Sohbet")
                                .font(AppTypography.button(size: 14))
                                .foregroundStyle(InkMockup.accentPink)
                        }
                    }
                    Button { showCompose = true } label: {
                        Label("Paylaş", systemImage: "square.and.pencil")
                            .font(AppTypography.button(size: 14))
                            .foregroundStyle(InkMockup.accentPink)
                    }
                }

                if posts.isEmpty, !isLoading {
                    emptyState
                }

                ForEach(posts) { post in
                    feedRow(post)
                }

                if isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, 20)
                } else if let loadError, posts.isEmpty {
                    Text(loadError)
                        .font(AppTypography.body())
                        .foregroundStyle(InkMockup.captionColor)
                }
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .studentScreenBackground()
        .navigationTitle("Topluluk")
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load(reset: true) }
        .navigationDestination(item: $selectedPost) { post in
            CommunityPostDetailView(post: post, feed: feed, hidesTabBar: hidesTabBar) { updated in
                upsert(updated)
            }
        }
        .sheet(isPresented: $showCompose) {
            CommunityComposeView(feed: feed) { created in
                posts.insert(created, at: 0)
            }
        }
        .sheet(item: $selectedAuthor) { CommunityAuthorSheet(author: $0) }
        .task { if posts.isEmpty { await load(reset: true) } }
        .onAppear { hidesTabBar.wrappedValue = true }
    }

    private func feedRow(_ post: FeedPostDTO) -> some View {
        CommunityPostCard(
            post: post,
            onLike: { Task { await like(post) } },
            onReply: { selectedPost = post },
            onAuthor: { selectedAuthor = post.author },
            onDelete: post.canDelete ? { Task { await remove(post) } } : nil,
            onReport: post.canDelete ? nil : { Task { await report(post) } }
        )
        .onAppear {
            if post.id == posts.last?.id { Task { await loadMore() } }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Henüz gönderi yok")
                .font(AppTypography.cardTitle())
                .foregroundStyle(InkMockup.textPrimary)
            Text("İlk paylaşımı sen yap. Metin, fotoğraf veya kısa video ekleyebilirsin.")
                .font(AppTypography.body(size: 14))
                .foregroundStyle(InkMockup.captionColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassChrome(radius: 18)
    }

    private func load(reset: Bool) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await feed.list(cursor: reset ? nil : nextCursor)
            posts = reset ? page.posts : posts + page.posts.filter { post in !posts.contains(where: { $0.id == post.id }) }
            nextCursor = page.nextCursor
            loadError = nil
        } catch {
            if posts.isEmpty { loadError = AuthErrorMessage.from(error) }
        }
    }

    private func loadMore() async {
        guard nextCursor != nil, !isLoading else { return }
        await load(reset: false)
    }

    private func like(_ post: FeedPostDTO) async {
        do {
            let result = try await feed.toggleLike(postId: post.id)
            XPToastStore.shared.present(result.xpAwarded)
            upsert(post, liked: result.liked, likeCount: result.likeCount)
        } catch {
            loadError = AuthErrorMessage.from(error)
        }
    }

    private func report(_ post: FeedPostDTO) async {
        try? await feed.reportPost(id: post.id)
    }

    private func remove(_ post: FeedPostDTO) async {
        try? await feed.deletePost(id: post.id)
        posts.removeAll { $0.id == post.id }
    }

    private func upsert(_ post: FeedPostDTO, liked: Bool? = nil, likeCount: Int? = nil) {
        var copy = post
        if let liked { copy.liked = liked }
        if let likeCount { copy.likeCount = likeCount }
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = copy
        }
    }
}

struct CommunityHomePreview: View {
    let post: FeedPostDTO?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Topluluk")
                    .font(AppTypography.sectionHeading(size: 24))
                    .tracking(AppTypography.tracking(forDisplaySize: 24))
                    .foregroundStyle(InkMockup.textPrimary)
                Spacer()
                Text("Tümünü Gör")
                    .font(AppTypography.mono(size: 12))
                    .foregroundStyle(InkMockup.accentPink)
            }

            if let post {
                CommunityPostCard(post: post, compact: true, showsActions: false)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Topluluk henüz sessiz")
                        .font(AppTypography.cardTitle())
                        .foregroundStyle(InkMockup.textPrimary)
                    Text("İlk paylaşımı sen yap.")
                        .font(AppTypography.body(size: 14))
                        .foregroundStyle(InkMockup.captionColor)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassChrome(radius: 18)
            }
        }
    }
}
