import SwiftUI

// MARK: - Score ring with numeric /10 label

struct FeedbackScoreRing: View {
    let score: Int
    let maxScore: Int
    var size: CGFloat = 80

    private var progress: Double {
        guard maxScore > 0 else { return 0 }
        return Double(score) / Double(maxScore)
    }

    private var ringColor: Color {
        if progress >= 0.8 { return .inkSuccess }
        if progress >= 0.5 { return .inkWarning }
        return .inkError
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.inkBorder, lineWidth: 5)

            // Fill
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            // Label
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkTextPrimary)

                Text("/\(maxScore)")
                    .font(.system(size: size * 0.14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkTextTertiary)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 24) {
        FeedbackScoreRing(score: 9, maxScore: 10)
        FeedbackScoreRing(score: 6, maxScore: 10)
        FeedbackScoreRing(score: 3, maxScore: 10)
    }
    .padding()
}
