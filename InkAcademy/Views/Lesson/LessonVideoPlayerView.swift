import SwiftUI
import AVKit

// MARK: - Embedded video player with placeholder

struct LessonVideoPlayerView: View {
    let player: AVPlayer?
    let duration: String

    @State private var isPlaying = false

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .frame(height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .onDisappear {
                        player.pause()
                    }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.inkBlack)
                .frame(height: 210)

            VStack(spacing: 10) {
                Image(systemName: "play.slash.fill")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))

                Text("Video yakında eklenecek")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}

#Preview("With player") {
    LessonVideoPlayerView(
        player: AVPlayer(url: URL(string: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4")!),
        duration: "12:00"
    )
    .padding()
}

#Preview("No video") {
    LessonVideoPlayerView(player: nil, duration: "0:00")
        .padding()
}
