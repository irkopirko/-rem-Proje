import SwiftUI
import UIKit
import AVFoundation

/// 1. tür mockup / analiz dokümanı tipografi ve bileşenleri.
enum InkMockup {
    static let screenHorizontal: CGFloat = 28
    static let fieldHeight: CGFloat = 52
    static let buttonHeight: CGFloat = 52
    static let cardRadius: CGFloat = 24
    /// Öğrenci sekmelerinin (Eğitimler, Ödevler, Ürünler, Hesabım) ortak başlık yazısı.
    static let screenTitleFont = AppTypography.pageTitle()

    /// Öğrenci (giriş sonrası) — koyu stüdyo.
    static let textPrimary = InkGlass.textPrimary
    static let captionColor = InkGlass.textSecondary
    static let placeholderColor = InkGlass.textSecondary.opacity(0.72)
    static let fieldFill = InkGlass.surface
    static let fieldBorder = InkGlass.border
    static let cardFill = InkGlass.surface
    static let accentPink = InkGlass.rose
}

/// Giriş / kaydol / bize ulaş — açık mockup paleti, öğrenci temasına karışmaz.
enum InkAuth {
    static let textPrimary = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let captionColor = Color(red: 0.20, green: 0.20, blue: 0.21)
    static let placeholderColor = Color(red: 0.30, green: 0.30, blue: 0.31)
    static let fieldFill = Color(red: 0.93, green: 0.93, blue: 0.94)
    static let fieldBorder = Color.black.opacity(0.18)
}

private struct InkStudioChromeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var inkStudioChrome: Bool {
        get { self[InkStudioChromeKey.self] }
        set { self[InkStudioChromeKey.self] = newValue }
    }
}

struct InkMockSectionTitle: View {
    let text: String
    var body: some View {
        Text(AppTypography.turkishUppercased(text))
            .font(InkMockup.screenTitleFont)
            .tracking(AppTypography.tracking(forDisplaySize: 34, uppercase: true))
            .foregroundStyle(InkMockup.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .accessibilityAddTraits(.isHeader)
    }
}

struct InkMockSubheading: View {
    let text: String
    @Environment(\.inkStudioChrome) private var studio
    var body: some View {
        Text(text)
            .font(studio ? AppTypography.body(size: 14) : .system(size: 14, weight: .regular))
            .foregroundStyle(studio ? InkMockup.captionColor : InkAuth.captionColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InkMockTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var invalid = false
    var textContentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    @Environment(\.inkStudioChrome) private var studio

    var body: some View {
        Group {
            if isSecure {
                SecureField(text: $text, prompt: prompt) { Text(placeholder) }
            } else {
                TextField(text: $text, prompt: prompt) { Text(placeholder) }
            }
        }
        .textContentType(textContentType)
        .keyboardType(keyboardType)
        .textInputAutocapitalization(autocapitalization)
        .autocorrectionDisabled(isSecure || keyboardType == .emailAddress)
        .font(studio ? AppTypography.body(size: 16) : .system(size: 16))
        .foregroundStyle(studio ? InkMockup.textPrimary : InkAuth.textPrimary)
        .tint(studio ? InkMockup.accentPink : InkAuth.textPrimary)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: InkMockup.fieldHeight)
        .background(invalid ? Color.inkError.opacity(0.10) : (studio ? InkMockup.fieldFill.opacity(0.72) : InkAuth.fieldFill))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(invalid ? Color.inkError : (studio ? InkMockup.fieldBorder : InkAuth.fieldBorder), lineWidth: invalid ? 1.5 : 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(invalid ? Color.inkError : (studio ? InkMockup.placeholderColor : InkAuth.placeholderColor))
    }
}

/// Doğum tarihi gün / ay / yıl akordeon seçicileri.
struct InkMockMenuPicker: View {
    let title: String
    @Binding var selection: Int?
    let options: [Int]
    var label: (Int) -> String = { String($0) }
    var invalid = false

    var body: some View {
        Menu {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { value in
                    Text(label(value)).tag(Optional(value))
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selection.map(label) ?? title)
                    .font(AppTypography.body(size: 15))
                    .foregroundStyle(selection == nil ? InkMockup.placeholderColor : InkMockup.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 2)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(InkMockup.placeholderColor)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: InkMockup.fieldHeight)
            .background(invalid ? Color.inkError.opacity(0.10) : InkMockup.fieldFill.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(invalid ? Color.inkError : InkMockup.fieldBorder, lineWidth: invalid ? 1.5 : 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

struct InkMockPrimaryButton: View {
    let title: String
    var isLoading = false
    var action: () -> Void
    @Environment(\.inkStudioChrome) private var studio
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                }
                Text(title)
                    .font(studio ? AppTypography.button() : .system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: InkMockup.buttonHeight)
            .background {
                if studio {
                    glassFill(radius: InkGlass.smallRadius, emphasized: true, reduceTransparency: false, colorScheme: colorScheme)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black)
                }
            }
        }
        .disabled(isLoading)
    }
}

/// Siyah çerçeveli, şeffaf dolgulu ikincil buton (ör. “Kaydol”).
struct InkMockSecondaryButton: View {
    let title: String
    var action: () -> Void
    @Environment(\.inkStudioChrome) private var studio
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(studio ? AppTypography.button() : .system(size: 17, weight: .semibold))
                .foregroundStyle(studio ? InkMockup.textPrimary : InkAuth.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: InkMockup.buttonHeight)
                .background {
                    if studio {
                        glassFill(radius: InkGlass.smallRadius, emphasized: false, reduceTransparency: false, colorScheme: colorScheme)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.55))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: studio ? InkGlass.smallRadius : 12, style: .continuous)
                        .stroke(studio ? InkMockup.fieldBorder : Color.black, lineWidth: studio ? 0.8 : 1.5)
                )
        }
    }
}

struct InkMockCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        GlassCard(radius: InkMockup.cardRadius, padding: 16) {
            content
        }
    }
}

/// Mockup’taki büyük yuvarlak köşeli menü satırı (Hesabım vb.).
struct InkMockMenuButton<Destination: View>: View {
    let title: String
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            Text(title)
                .font(AppTypography.cardTitle())
                .foregroundStyle(InkMockup.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .glassChrome(radius: 22)
        }
        .buttonStyle(.plain)
    }
}

/// Ödev listesindeki kapsül satır.
struct InkMockHomeworkPill: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.cardTitle(size: 17))
                .foregroundStyle(InkMockup.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.caption(size: 12))
                    .foregroundStyle(InkMockup.captionColor)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassChrome(radius: 18)
    }
}

struct AuthFormLayout<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.top, 48)
            .padding(.bottom, 32)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Backgrounds

extension View {
    /// Tam ekran resim arka planı. `background` içinde olduğu için resmin boyutu
    /// içerik yerleşimini genişletmez.
    func inkImageBackground(_ name: String) -> some View {
        background {
            GeometryReader { proxy in
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
        }
    }

    /// `motion.mov` döngüsel video arka planı. Video açılmazsa `image-background` kalır.
    func inkMotionBackground(dimming: Double = 0) -> some View {
        background {
            ZStack {
                inkImageFill("image-background")
                LoopingVideoView(resource: "motion", fileExtension: "mov")
                if dimming > 0 {
                    Color.black.opacity(dimming)
                }
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func inkImageFill(_ name: String) -> some View {
        GeometryReader { proxy in
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
    }
}

/// Kontrolleri olmayan, ekranı dolduran (aspect fill) sessiz döngü video.
struct LoopingVideoView: UIViewRepresentable {
    let resource: String
    let fileExtension: String

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else { return view }
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false
        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: item)
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.backgroundColor = UIColor.clear.cgColor
        DispatchQueue.main.async { player.play() }
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var looper: AVPlayerLooper?
    }

    final class PlayerContainerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
