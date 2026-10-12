import PhotosUI
import SwiftUI
import UIKit

struct CommunityPostDetailView: View {
    @State private var post: FeedPostDTO
    let feed: CommunityFeedService
    var hidesTabBar: Binding<Bool> = .constant(false)
    var onChange: (FeedPostDTO) -> Void

    @State private var replies: [FeedReplyDTO] = []
    @State private var replyText = ""
    @State private var parentReply: FeedReplyDTO?
    @State private var pickerItem: PhotosPickerItem?
    @State private var draftImage: FeedDraftMedia?
    @State private var isSending = false
    @State private var selectedAuthor: FeedAuthorDTO?
    @State private var errorMessage: String?
    @State private var showPhotos = false

    init(post: FeedPostDTO, feed: CommunityFeedService, hidesTabBar: Binding<Bool> = .constant(false), onChange: @escaping (FeedPostDTO) -> Void) {
        _post = State(initialValue: post)
        self.feed = feed
        self.hidesTabBar = hidesTabBar
        self.onChange = onChange
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CommunityPostCard(
                    post: post,
                    onLike: { Task { await like() } },
                    onReply: { parentReply = nil },
                    onAuthor: { selectedAuthor = post.author },
                    onDelete: post.canDelete ? { Task { try? await feed.deletePost(id: post.id) } } : nil,
                    onReport: post.canDelete ? nil : { Task { try? await feed.reportPost(id: post.id) } }
                )

                Text("Yanıtlar")
                    .font(AppTypography.subheading(size: 16))
                    .foregroundStyle(InkMockup.textPrimary)

                if replies.isEmpty {
                    Text("İlk yanıtı sen yaz.")
                        .font(AppTypography.body(size: 14))
                        .foregroundStyle(InkMockup.captionColor)
                }

                ForEach(replies) { item in
                    replyRow(item)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(AppTypography.caption())
                        .foregroundStyle(Color.inkError)
                }
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .studentScreenBackground()
        .navigationTitle("Gönderi")
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) { composer }
        .sheet(item: $selectedAuthor) { CommunityAuthorSheet(author: $0) }
        .photosPicker(isPresented: $showPhotos, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                draftImage = try? await FeedDraftMedia.load(item, imagesOnly: true)
                pickerItem = nil
            }
        }
        .task { await loadReplies() }
        .onAppear { hidesTabBar.wrappedValue = true }
    }

    private func replyRow(_ reply: FeedReplyDTO) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if reply.parentReplyId != nil {
                Color.clear.frame(width: 18)
            }
            Button { selectedAuthor = reply.author } label: {
                ProfileAvatarView(url: reply.author.photoURL, initials: reply.author.initials, size: 32, frame: reply.author.avatarFrame, rank: reply.author.academyRank)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(reply.author.name)
                        .font(AppTypography.cardTitle(size: 14))
                        .foregroundStyle(InkMockup.textPrimary)
                    if let publicRankCaption = reply.author.publicRankCaption {
                        Text(publicRankCaption)
                            .font(AppTypography.mono(size: 10))
                            .foregroundStyle(InkMockup.captionColor)
                    }
                    Text(RelativeTimeFormat.display(reply.createdAt))
                        .font(AppTypography.mono(size: 10))
                        .foregroundStyle(InkMockup.captionColor)
                    Spacer()
                    Menu {
                        Button("Yanıtla") { parentReply = reply }
                        if reply.canDelete {
                            Button("Sil", role: .destructive) { Task { await deleteReply(reply) } }
                        } else {
                            Button("Bildir") { Task { try? await feed.reportReply(id: reply.id) } }
                        }
                    } label: {
                        Image(systemName: "ellipsis").foregroundStyle(InkMockup.captionColor)
                    }
                }
                if !reply.body.isEmpty {
                    Text(reply.body)
                        .font(AppTypography.body(size: 14))
                        .foregroundStyle(InkMockup.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !reply.media.isEmpty {
                    CommunityMediaStrip(media: reply.media, compact: true)
                }
            }
        }
        .padding(12)
        .glassChrome(radius: 16)
    }

    private var canSend: Bool {
        !isSending && (replyText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 || draftImage != nil)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let parentReply {
                HStack {
                    Text("\(parentReply.author.name) adlı kişiye yanıt")
                        .font(AppTypography.caption())
                        .foregroundStyle(InkMockup.captionColor)
                    Spacer()
                    Button("Vazgeç") { self.parentReply = nil }
                        .font(AppTypography.caption())
                        .foregroundStyle(InkMockup.accentPink)
                }
            }
            if let draftImage, let preview = draftImage.preview {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Button { self.draftImage = nil } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.white)
                    }
                    .padding(4)
                }
            }
            HStack(alignment: .bottom, spacing: 8) {
                Button { showPhotos = true } label: {
                    Image(systemName: "photo")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(InkMockup.accentPink)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                TextField("Yanıt yaz…", text: $replyText, axis: .vertical)
                    .lineLimit(1...4)
                    .font(AppTypography.body(size: 15))
                    .padding(12)
                    .glassChrome(radius: 16)
                Button {
                    Task { await sendReply() }
                } label: {
                    if isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(canSend ? InkMockup.accentPink : InkMockup.captionColor)
                    }
                }
                .disabled(!canSend)
            }
        }
        .padding(.horizontal, InkMockup.screenHorizontal)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(InkGlass.background.opacity(0.96))
    }

    private func loadReplies() async {
        replies = (try? await feed.replies(postId: post.id)) ?? []
        if let fresh = try? await feed.post(id: post.id) {
            post = fresh
            onChange(fresh)
        }
    }

    private func like() async {
        do {
            let result = try await feed.toggleLike(postId: post.id)
            XPToastStore.shared.present(result.xpAwarded)
            post.liked = result.liked
            post.likeCount = result.likeCount
            onChange(post)
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }

    private func sendReply() async {
        let body = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = draftImage
        guard body.count >= 2 || image != nil else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            var result = try await feed.createReply(
                postId: post.id,
                body: body,
                parentReplyId: parentReply?.id,
                hasMedia: image != nil,
                clientRequestId: UUID().uuidString.lowercased()
            )
            if let image, let data = image.data {
                let media = try await feed.uploadReplyMedia(replyId: result.reply.id, data: data, contentType: image.contentType)
                result.reply.media = [media]
            }
            XPToastStore.shared.present(result.xpAwarded)
            replies.append(result.reply)
            post.replyCount += 1
            replyText = ""
            draftImage = nil
            parentReply = nil
            onChange(post)
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }

    private func deleteReply(_ reply: FeedReplyDTO) async {
        try? await feed.deleteReply(id: reply.id)
        replies.removeAll { $0.id == reply.id }
        post.replyCount = max(0, post.replyCount - 1)
        onChange(post)
    }
}
