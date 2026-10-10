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
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkTextPrimary)
            Text("/ \(maxScore)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkTextSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}
