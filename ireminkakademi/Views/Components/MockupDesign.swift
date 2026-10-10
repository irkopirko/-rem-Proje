import SwiftUI
import UIKit
import AVFoundation

/// 1. tür mockup / analiz dokümanı tipografi ve bileşenleri.
enum InkMockup {
    static let screenHorizontal: CGFloat = 28
    static let fieldHeight: CGFloat = 52
    static let buttonHeight: CGFloat = 52
    static let cardRadius: CGFloat = 14
    /// Öğrenci sekmelerinin (Eğitimler, Ödevler, Ürünler, Hesabım) ortak başlık yazısı.
    static let screenTitleFont = Font.system(size: 32, weight: .heavy)

    /// Büyük puntolu metin — siyah.
    static let textPrimary = Color(red: 0.07, green: 0.07, blue: 0.07)
    /// Küçük puntolu açıklamalar — siyaha yakın koyu gri.
    static let captionColor = Color(red: 0.20, green: 0.20, blue: 0.21)
    /// Input içindeki “E-posta / İsim …” yazıları.
    static let placeholderColor = Color(red: 0.30, green: 0.30, blue: 0.31)
    /// Input zemini — saf beyaz yerine açık gri.
    static let fieldFill = Color(red: 0.93, green: 0.93, blue: 0.94)
    static let fieldBorder = Color.black.opacity(0.18)
    /// Öğrenci ekranı kartları — açık gri kutu.
    static let cardFill = Color(red: 0.91, green: 0.90, blue: 0.89)
    /// Vurgu (mockup’taki koyu pembe ton).
    static let accentPink = Color(red: 0.55, green: 0.28, blue: 0.42)
}

struct InkMockSectionTitle: View {
    let text: String
    var body: some View {
        Text(text.uppercased(with: Locale(identifier: "tr_TR")))
            .font(InkMockup.screenTitleFont)
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
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(InkMockup.captionColor)
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
        .font(.system(size: 16))
        .foregroundStyle(InkMockup.textPrimary)
        .tint(InkMockup.textPrimary)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: InkMockup.fieldHeight)
        .background(invalid ? Color.inkError.opacity(0.10) : InkMockup.fieldFill)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(invalid ? Color.inkError : InkMockup.fieldBorder, lineWidth: invalid ? 1.5 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(invalid ? Color.inkError : InkMockup.placeholderColor)
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
                    .font(.system(size: 15))
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
            .background(invalid ? Color.inkError.opacity(0.10) : InkMockup.fieldFill)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(invalid ? Color.inkError : InkMockup.fieldBorder, lineWidth: invalid ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

struct InkMockPrimaryButton: View {
    let title: String
    var isLoading = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: InkMockup.buttonHeight)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(isLoading)
    }
}

/// Siyah çerçeveli, şeffaf dolgulu ikincil buton (ör. “Kaydol”).
struct InkMockSecondaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(InkMockup.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: InkMockup.buttonHeight)
                .background(Color.white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct InkMockCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(InkMockup.cardFill.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: InkMockup.cardRadius, style: .continuous))
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
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(InkMockup.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(InkMockup.cardFill.opacity(0.98))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(InkMockup.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(InkMockup.captionColor)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(InkMockup.cardFill.opacity(0.98))
        .clipShape(Capsule())
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

    /// `motion.mov` döngüsel video arka planı.
    func inkMotionBackground(dimming: Double = 0) -> some View {
        background {
            ZStack {
                LoopingVideoView(resource: "motion", fileExtension: "mov")
                if dimming > 0 {
                    Color.black.opacity(dimming)
                }
            }
            .ignoresSafeArea()
        }
    }
}

/// Kontrolleri olmayan, ekranı dolduran (aspect fill) sessiz döngü video.
struct LoopingVideoView: UIViewRepresentable {
    let resource: String
    let fileExtension: String

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else { return view }
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: item)
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        player.play()
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
