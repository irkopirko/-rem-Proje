import SwiftUI

struct ProgressRingView: View {
    var progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 60
    var showPercentage: Bool = true
    var trackColor: Color = Color.inkDivider
    var tintColor: Color? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    resolvedTint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkTextPrimary)
            }
        }
        .frame(width: size, height: size)
    }

    private var resolvedTint: Color {
        if let tintColor { return tintColor }
        return progress >= 1.0 ? .inkAccent : .inkAccent
    }
}

#Preview {
    HStack(spacing: 20) {
        ProgressRingView(progress: 0.33)
        ProgressRingView(progress: 0.75, size: 80)
        ProgressRingView(progress: 1.0, size: 50)
    }
    .padding()
    .background(Color.inkBackground)
}