import SwiftUI

struct CountdownTimerView: View {
    let timeText: String
    var isUrgent: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12, weight: .semibold))
            Text("Süre: \(timeText)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
        }
        .foregroundStyle(isUrgent ? Color.inkWarning : Color.inkTextPrimary)
        .accessibilityLabel("Kalan süre \(timeText)")
    }
}

#Preview {
    VStack(spacing: 12) {
        CountdownTimerView(timeText: "00:45")
        CountdownTimerView(timeText: "00:08", isUrgent: true)
    }
    .padding()
    .inkPageBackground()
}
