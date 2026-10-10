import SwiftUI

struct XPProgressView: View {
    let progress: Double
    var tint: Color = .inkTeal

    private var clamped: CGFloat {
        CGFloat(min(max(progress, 0), 1))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.inkSurfaceSecondary.opacity(0.85))
                    .frame(height: 10)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, geo.size.width * clamped), height: 10)
            }
        }
        .frame(height: 10)
        .accessibilityLabel("İlerleme")
        .accessibilityValue("\(Int(clamped * 100)) yüzde")
    }
}

#Preview {
    VStack(spacing: 20) {
        XPProgressView(progress: 0.35, tint: .inkAccent)
        XPProgressView(progress: 0.92, tint: .inkTeal)
    }
    .padding()
    .background(Color(.systemGray6))
}
