import AVKit
import SwiftUI

struct CommunityPostCard: View {
    let post: FeedPostDTO
    var compact = false
    var showsActions = true
    var onLike: (() -> Void)?
    var onReply: (() -> Void)?
    var onAuthor: (() -> Void)?
    var onDelete: (() -> Void)?
    var onReport: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            header
            if !post.previewText.isEmpty {
                Text(post.previewText)
                    .font(compact ? AppTypography.body(size: 14) : AppTypography.body())
                    .foregroundStyle(InkMockup.textPrimary)
                    .lineLimit(compact ? 3 : nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !post.media.isEmpty {
                CommunityMediaStrip(media: post.media, compact: compact)
            }
            if showsActions {
                actions
            } else {
                counts
            }
        }
        .padding(compact ? 14 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassChrome(radius: 18)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: { onAuthor?() }) {
                ProfileAvatarView(
                    url: post.author.photoURL,
                    initials: post.author.initials,
                    size: compact ? 36 : 42,
                    frame: post.author.avatarFrame,
                    rank: post.author.academyRank
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Button(action: { onAuthor?() }) {
                    Text(post.author.name)
                        .font(AppTypography.cardTitle(size: 15))
                        .foregroundStyle(InkMockup.textPrimary)
                }
                .buttonStyle(.plain)
                if let publicRankCaption = post.author.publicRankCaption {
                    Text(publicRankCaption)
                        .font(AppTypography.mono(size: 11))
                        .foregroundStyle(InkMockup.captionColor)
                }
                Text(RelativeTimeFormat.display(post.createdAt))
                    .font(AppTypography.mono(size: 11))
                    .foregroundStyle(InkMockup.captionColor)
            }
            Spacer(minLength: 0)
            if onDelete != nil || onReport != nil {
                Menu {
                    if let onDelete { Button("Gönderiyi sil", role: .destructive, action: onDelete) }
                    if let onReport { Button("Bildir", action: onReport) }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(InkMockup.captionColor)
                        .padding(6)
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 18) {
            Button(action: { onLike?() }) {
                Label("\(post.likeCount)", systemImage: post.liked ? "heart.fill" : "heart")
                    .foregroundStyle(post.liked ? InkMockup.accentPink : InkMockup.captionColor)
            }
            .buttonStyle(.plain)
            Button(action: { onReply?() }) {
                Label("\(post.replyCount)", systemImage: "bubble.right")
                    .foregroundStyle(InkMockup.captionColor)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .font(AppTypography.mono(size: 12))
    }

    private var counts: some View {
        HStack(spacing: 14) {
            Label("\(post.likeCount)", systemImage: "heart")
            Label("\(post.replyCount)", systemImage: "bubble.right")
            Spacer()
        }
        .font(AppTypography.mono(size: 11))
        .foregroundStyle(InkMockup.captionColor)
    }
}

struct CommunityMediaStrip: View {
    let media: [FeedMediaDTO]
    var compact = false

    var body: some View {
        let height: CGFloat = compact ? 140 : 220
        if media.count == 1, let item = media.first {
            CommunityMediaTile(item: item)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(media) { item in
                        CommunityMediaTile(item: item)
                            .frame(width: compact ? 160 : 220, height: height)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
    }
}

struct CommunityMediaTile: View {
    let item: FeedMediaDTO
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if item.isVideo, let url = item.resolvedURL {
                if let player {
                    VideoPlayer(player: player)
                } else {
                    InkMockup.cardFill
                    Button {
                        let created = AVPlayer(url: url)
                        created.isMuted = true
                        player = created
                        created.play()
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                ProductImageView(url: item.resolvedURL)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

struct CommunityAuthorSheet: View {
    let author: FeedAuthorDTO
    @State private var showPhoto = false

    var body: some View {
        VStack(spacing: 16) {
            Button {
                if author.photoURL != nil { showPhoto = true }
            } label: {
                ProfileAvatarView(url: author.photoURL, initials: author.initials, size: 84, frame: author.avatarFrame, rank: author.academyRank)
            }
            .buttonStyle(.plain)
            .disabled(author.photoURL == nil)
            .accessibilityLabel(author.photoURL == nil ? "Profil fotoğrafı yok" : "Profil fotoğrafını büyüt")

            Text(author.name)
                .font(AppTypography.cardTitle(size: 20))
                .foregroundStyle(InkMockup.textPrimary)
            if let username = author.username {
                Text("@\(username)")
                    .font(AppTypography.mono(size: 13))
                    .foregroundStyle(InkMockup.captionColor)
            }
            if let publicRankCaption = author.publicRankCaption {
                Text(publicRankCaption)
                    .font(AppTypography.monoMedium(size: 12))
                    .tracking(0.8)
                    .foregroundStyle(InkMockup.accentPink)
            }
            Text("Sohbet, üstteki mesaj ikonundan açılır. Burada yalnızca herkese açık profil görünür.")
                .font(AppTypography.body(size: 14))
                .foregroundStyle(InkMockup.captionColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .studentScreenBackground()
        .presentationDetents([.medium])
        .fullScreenCover(isPresented: $showPhoto) {
            CommunityProfilePhotoViewer(url: author.photoURL, name: author.name)
        }
    }
}

private struct CommunityProfilePhotoViewer: View {
    let url: URL?
    let name: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 18) {
                Spacer(minLength: 0)
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                                .shadow(color: .black.opacity(0.4), radius: 24, y: 8)
                        case .failure:
                            Text("Fotoğraf yüklenemedi")
                                .font(AppTypography.body())
                                .foregroundStyle(.white.opacity(0.7))
                        default:
                            ProgressView().tint(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: 520)
                }
                Text(name)
                    .font(AppTypography.cardTitle(size: 18))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Kapat")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                Spacer()
            }
        }
        .statusBarHidden(true)
    }
}
