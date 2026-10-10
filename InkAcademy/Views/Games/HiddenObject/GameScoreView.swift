import SwiftUI

struct GameScoreView: View {
    let score: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.inkAccent)
            Text("\(score)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkTextPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

#Preview {
    GameScoreView(score: 10)
        .padding()
        .inkPageBackground()
}
