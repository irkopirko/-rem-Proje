import SwiftUI

/// Score label — top-right.
struct GameScore: View {
    let score: Int
    let maxScore: Int

    init(score: Int, maxScore: Int = HiddenObjectGameConfig.standard.maxScore) {
        self.score = score
        self.maxScore = maxScore
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.inkAccent)
            Text("\(score)")
                .font(AppTypography.displayStat(size: 20))
                .foregroundStyle(InkMockup.textPrimary)
            Text("/ \(maxScore)")
                .font(AppTypography.mono(size: 11))
                .foregroundStyle(InkMockup.captionColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassChrome(radius: 16)
    }
}
