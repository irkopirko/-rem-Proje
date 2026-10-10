import SwiftUI

struct MistakeRegionOverlay: View {
    let mistake: TattooMistake
    let sceneSize: CGSize
    var style: Style = .foundHighlight

    enum Style {
        case foundHighlight
        case answerReveal
    }

    var body: some View {
        let rect = mistake.rect(in: sceneSize)
        let color: Color = style == .foundHighlight ? Color.inkSage : Color.inkAccent

        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(color, lineWidth: style == .answerReveal ? 2.5 : 3)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(style == .answerReveal ? 0.15 : 0.12))
            )
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
    }
}
