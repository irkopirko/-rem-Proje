import AVKit
import SwiftUI
import WebKit

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
    private(set) var embedURL: URL?
    let player = AVPlayer()

    @ObservationIgnored private let catalog = CatalogService()
    @ObservationIgnored private let reportsProgress: Bool
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?
    @ObservationIgnored private var maxPosition = 0
    @ObservationIgnored private var lastReported = -1
    @ObservationIgnored private var completed = false
    @ObservationIgnored private var didRefreshBadges = false

    init(video: VideoDTO, reportsProgress: Bool) {
        self.video = video
        self.reportsProgress = reportsProgress
        self.completed = video.completed == true
        self.didRefreshBadges = video.completed == true
        player.automaticallyWaitsToMinimizeStalling = true
        player.audiovisualBackgroundPlaybackPolicy = .automatic
    }

    func start() async {
        guard player.currentItem == nil else {
            if phase == .ready { player.play() }
            return
        }
        phase = .loading
        embedURL = nil
        do {
            let playback = try await catalog.fetchPlayback(videoId: video.id)
            video = playback.video

            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .moviePlayback)
            try? session.setActive(true)

            if let embed = playback.embedUrl, let url = URL(string: embed) {
                embedURL = url
                phase = .ready
                return
            }

            guard let url = URL(string: playback.hlsUrl) else { throw InkAPIError.invalidURL }

            let asset = AVURLAsset(url: url, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: true,
            ])
            let item = AVPlayerItem(asset: asset)
            item.preferredPeakBitRate = 0
            item.preferredMaximumResolution = .zero
            item.preferredForwardBufferDuration = 3
            player.replaceCurrentItem(with: item)

            try await waitUntilPlayable(item)

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
            phase = .failed(Self.playbackErrorMessage(error))
        }
    }

    func retry() async {
        player.replaceCurrentItem(with: nil)
        embedURL = nil
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        timeObserver = nil
        endObserver = nil
        lastReported = -1
        await start()
    }

    func applyEmbedTime(seconds: Double, duration: Double) {
        let position = Int(seconds.rounded(.down))
        maxPosition = max(maxPosition, position)
        if duration > 0, seconds >= duration * 0.9 { completed = true }
        if abs(position - lastReported) >= 15 { report(force: false) }
    }

    func markEmbedEnded() {
        completed = true
        report(force: true)
    }

    func stop() {
        report(force: true)
        player.pause()
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        timeObserver = nil
        endObserver = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func waitUntilPlayable(_ item: AVPlayerItem) async throws {
        let deadline = Date().addingTimeInterval(25)
        while item.status == .unknown {
            if Date() > deadline {
                throw InkAPIError.server("Video yüklenemedi. Biraz sonra tekrar dene.")
            }
            try await Task.sleep(for: .milliseconds(150))
        }
        if item.status == .failed {
            throw item.error ?? InkAPIError.server("Video açılamadı.")
        }
    }

    private static func playbackErrorMessage(_ error: Error) -> String {
        let raw = error.localizedDescription
        if raw.localizedCaseInsensitiveContains("permission")
            || raw.localizedCaseInsensitiveContains("403")
            || raw.localizedCaseInsensitiveContains("forbidden") {
            return "Video şu an oynatılamıyor. Biraz sonra tekrar dene."
        }
        if raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Video açılamadı."
        }
        return raw
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
        guard reportsProgress, player.currentItem != nil || embedURL != nil else { return }
        let seconds = player.currentItem != nil ? player.currentTime().seconds : Double(maxPosition)
        let position = seconds.isFinite ? Int(seconds) : maxPosition
        guard force || position != lastReported else { return }
        lastReported = position
        let id = video.id, watched = maxPosition, done = completed
        Task {
            try? await catalog.saveProgress(videoId: id, lastPositionSeconds: position, watchedSeconds: watched, completed: done)
            if done, !didRefreshBadges {
                didRefreshBadges = true
                _ = try? await catalog.fetchBadgeProgress()
            }
        }
    }
}

struct VideoPlayerScreen: View {
    let reportsProgress: Bool
    @State private var model: VideoPlaybackModel

    init(video: VideoDTO, reportsProgress: Bool) {
        self.reportsProgress = reportsProgress
        _model = State(initialValue: VideoPlaybackModel(video: video, reportsProgress: reportsProgress))
    }

    var body: some View {
        VStack(spacing: 0) {
            playerArea
                .aspectRatio(aspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(Color.black)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ders \(model.video.numberLabel)")
                        .font(AppTypography.monoMedium(size: 12))
                        .tracking(1.0)
                        .foregroundStyle(InkMockup.captionColor)
                    Text(model.video.title)
                        .font(AppTypography.sectionHeading())
                        .tracking(AppTypography.tracking(forDisplaySize: 26))
                        .foregroundStyle(InkMockup.textPrimary)
                    HStack(spacing: 8) {
                        Text(model.video.durationLabel)
                        if let quality = model.video.qualityLabel { Text("· \(quality)") }
                    }
                    .font(AppTypography.mono(size: 12))
                    .foregroundStyle(InkMockup.captionColor)

                    if let desc = model.video.description, !desc.isEmpty {
                        Text(desc)
                            .font(AppTypography.body())
                            .foregroundStyle(InkMockup.textPrimary.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                    }
                }
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
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
                ProgressView("Video hazırlanıyor…")
                    .tint(.white)
                    .foregroundStyle(.white)
                    .controlSize(.large)
            }
        case .ready:
            if let embedURL = model.embedURL {
                BunnyEmbedPlayer(
                    url: embedURL,
                    resumeSeconds: model.video.lastPositionSeconds ?? 0,
                    onTime: { seconds, duration in
                        model.applyEmbedTime(seconds: seconds, duration: duration)
                    },
                    onEnded: { model.markEmbedEnded() }
                )
            } else {
                VideoPlayer(player: model.player)
            }
        case .failed(let message):
            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30))
                Text(message)
                    .font(AppTypography.body(size: 14))
                    .multilineTextAlignment(.center)
                Button("Tekrar dene") {
                    Task { await model.retry() }
                }
                .font(AppTypography.button())
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(InkGlass.rose, in: Capsule())
            }
            .foregroundStyle(.white)
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Bunny Stream iframe. Direct HLS is blocked when the library forbids raw CDN files.
private struct BunnyEmbedPlayer: UIViewRepresentable {
    let url: URL
    var resumeSeconds: Int = 0
    var onTime: (Double, Double) -> Void
    var onEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(resumeSeconds: resumeSeconds, onTime: onTime, onEnded: onEnded)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(context.coordinator, name: "bunny")
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.isScrollEnabled = false
        web.scrollView.backgroundColor = .black
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        context.coordinator.onTime = onTime
        context.coordinator.onEnded = onEnded
        guard context.coordinator.loadedURL != url else { return }
        context.coordinator.loadedURL = url
        web.loadHTMLString(Self.page(url: url, resumeSeconds: resumeSeconds), baseURL: URL(string: "https://iframe.mediadelivery.net"))
    }

    static func dismantleUIView(_ web: WKWebView, coordinator: Coordinator) {
        web.configuration.userContentController.removeScriptMessageHandler(forName: "bunny")
        web.stopLoading()
    }

    private static func page(url: URL, resumeSeconds: Int) -> String {
        let src = url.absoluteString.replacingOccurrences(of: "&", with: "&amp;")
        let resume = max(0, resumeSeconds)
        return """
        <!DOCTYPE html>
        <html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <style>
          html,body,#box{margin:0;padding:0;background:#000;height:100%;overflow:hidden}
          iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
        </style>
        </head><body>
        <div id="box">
          <iframe id="player" src="\(src)" allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen></iframe>
        </div>
        <script>
        var resume = \(resume);
        window.addEventListener('message', function (e) {
          var d = e.data;
          if (typeof d === 'string') { try { d = JSON.parse(d); } catch (err) { return; } }
          if (!d || d.context !== 'player.js') return;
          if (d.event === 'ready' && resume > 5) {
            var frame = document.getElementById('player');
            if (frame && frame.contentWindow) {
              frame.contentWindow.postMessage(JSON.stringify({
                context: 'player.js', version: '0.0.11', method: 'setCurrentTime', value: resume
              }), '*');
            }
            resume = 0;
          }
          var value = d.value || {};
          if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.bunny) {
            window.webkit.messageHandlers.bunny.postMessage({
              event: d.event || '',
              seconds: value.seconds,
              duration: value.duration
            });
          }
        });
        </script>
        </body></html>
        """
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var loadedURL: URL?
        var resumeSeconds: Int
        var onTime: (Double, Double) -> Void
        var onEnded: () -> Void

        init(resumeSeconds: Int, onTime: @escaping (Double, Double) -> Void, onEnded: @escaping () -> Void) {
            self.resumeSeconds = resumeSeconds
            self.onTime = onTime
            self.onEnded = onEnded
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any] else { return }
            let event = body["event"] as? String ?? ""
            if event == "ended" {
                onEnded()
                return
            }
            let seconds = (body["seconds"] as? Double) ?? (body["seconds"] as? NSNumber)?.doubleValue ?? 0
            let duration = (body["duration"] as? Double) ?? (body["duration"] as? NSNumber)?.doubleValue ?? 0
            if event == "timeupdate" || seconds > 0 {
                onTime(seconds, duration)
            }
        }
    }
}
