import SwiftUI

struct AnimatedProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 60
    var showPercentage: Bool = true
    var trackColor: Color = Color.inkDivider
    var tintColor: Color? = nil

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(animatedProgress))
                .stroke(
                    resolvedTint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkTextPrimary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = clampedProgress
            }
        }
        .onChange(of: clampedProgress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.35)) {
                animatedProgress = newValue
            }
        }
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var resolvedTint: Color {
        if let tintColor { return tintColor }
        return clampedProgress >= 1.0 ? .inkAccent : .inkAccent
    }
}

#Preview {
    HStack(spacing: 20) {
        AnimatedProgressRing(progress: 0.33)
        AnimatedProgressRing(progress: 0.75, size: 80)
        AnimatedProgressRing(progress: 1.0, size: 50)
    }
    .padding()
    .background(Color.inkBackground)
}