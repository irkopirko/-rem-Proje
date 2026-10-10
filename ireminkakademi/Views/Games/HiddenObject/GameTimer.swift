import SwiftUI

/// Countdown label — top-left (01:00 → 00:59 …).
struct GameTimer: View {
    let timeText: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12, weight: .semibold))
            Text(timeText)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(Color.inkTextPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}
