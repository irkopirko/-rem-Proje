import AVKit
import SwiftUI

/// Bunny Stream HLS oynatıcı. Uyarlanabilir bit hızıyla bağlantının izin verdiği en yüksek
/// kaliteyi (yüklenen orijinal çözünürlüğe kadar) seçer; takılmayı önlemek için ara bellek kullanır.
@Observable
final class VideoPlaybackModel {
    enum Phase: Equatable {
        case loading
        case ready
        case failed(String)
    }

    private(set) var phase: Phase = .loading
    private(set) var video: VideoDTO
    let player = AVPlayer()

    @ObservationIgnored private let catalog = CatalogService()
    @ObservationIgnored private let reportsProgress: Bool
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?
    @ObservationIgnored private var maxPosition = 0
    @ObservationIgnored private var lastReported = -1
    @ObservationIgnored private var completed = false

    init(video: VideoDTO, reportsProgress: Bool) {
        self.video = video
        self.reportsProgress = reportsProgress
        self.completed = video.completed == true
        player.automaticallyWaitsToMinimizeStalling = true
    }

    func start() async {
        guard player.currentItem == nil else { return }
        phase = .loading
        do {
            let playback = try await catalog.fetchPlayback(videoId: video.id)
            video = playback.video
            guard let url = URL(string: playback.hlsUrl) else { throw InkAPIError.invalidURL }

            let item = AVPlayerItem(asset: AVURLAsset(url: url))
            item.preferredPeakBitRate = 0
            item.preferredMaximumResolution = .zero
            item.preferredForwardBufferDuration = 0
            player.replaceCurrentItem(with: item)

            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)

            let resume = playback.video.lastPositionSeconds ?? 0
            if !completed, resume > 5, playback.video.durationSeconds == 0 || resume < playback.video.durationSeconds - 10 {
                await player.seek(to: CMTime(seconds: Double(resume), preferredTimescale: 600))
                maxPosition = resume
            }
            observe(item)
            phase = .ready
            player.play()
        } catch InkAPIError.paymentRequired {
            phase = .failed("Videoları izlemek için aktif üyelik gerekiyor.")
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func stop() {
        report(force: true)
        player.pause()
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        timeObserver = nil
        endObserver = nil
    }

    private func observe(_ item: AVPlayerItem) {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated { self?.tick(time) }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.completed = true
                self?.report(force: true)
            }
        }
    }

    private func tick(_ time: CMTime) {
        guard time.isNumeric else { return }
        let position = Int(time.seconds)
        maxPosition = max(maxPosition, position)
        let duration = currentDuration
        if duration > 0, Double(position) >= Double(duration) * 0.9 { completed = true }
        if abs(position - lastReported) >= 15 { report(force: false) }
    }

    private var currentDuration: Int {
        if let seconds = player.currentItem?.duration.seconds, seconds.isFinite, seconds > 0 { return Int(seconds) }
        return video.durationSeconds
    }

    private func report(force: Bool) {
        guard reportsProgress, player.currentItem != nil else { return }
        let seconds = player.currentTime().seconds
        let position = seconds.isFinite ? Int(seconds) : 0
        guard force || position != lastReported else { return }
        lastReported = position
        let id = video.id, watched = maxPosition, done = completed
        Task { try? await catalog.saveProgress(videoId: id, lastPositionSeconds: position, watchedSeconds: watched, completed: done) }
    }
}

struct VideoPlayerScreen: View {
    let reportsProgress: Bool
    @State private var model: VideoPlaybackModel
    @Environment(\.dismiss) private var dismiss

    init(video: VideoDTO, reportsProgress: Bool) {
        self.reportsProgress = reportsProgress
        _model = State(initialValue: VideoPlaybackModel(video: video, reportsProgress: reportsProgress))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                playerArea
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Video \(model.video.numberLabel)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(InkMockup.captionColor)
                    Text(model.video.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(InkMockup.textPrimary)
                    HStack(spacing: 8) {
                        Text(model.video.durationLabel)
                        if let quality = model.video.qualityLabel { Text("· \(quality)") }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(InkMockup.captionColor)

                    if let desc = model.video.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 15))
                            .foregroundStyle(InkMockup.textPrimary.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                    }
                }
                .padding(.horizontal, InkMockup.screenHorizontal)
            }
            .padding(.bottom, 24)
        }
        .studentScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.start() }
        .onDisappear { model.stop() }
    }

    private var aspectRatio: CGFloat {
        guard let w = model.video.width, let h = model.video.height, w > 0, h > 0 else { return 16 / 9 }
        return max(CGFloat(w) / CGFloat(h), 9 / 16)
    }

    @ViewBuilder
    private var playerArea: some View {
        switch model.phase {
        case .loading:
            ZStack {
                VideoThumbnail(url: model.video.thumbnailURL)
                ProgressView().tint(.white).controlSize(.large)
            }
        case .ready:
            SystemVideoPlayer(player: model.player)
        case .failed(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30))
                Text(message)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// `AVPlayerViewController`: tam ekran, Resim içinde Resim, AirPlay ve hız seçimi.
private struct SystemVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.entersFullScreenWhenPlaybackBegins = false
        controller.exitsFullScreenWhenPlaybackEnds = true
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== player { controller.player = player }
    }
}
