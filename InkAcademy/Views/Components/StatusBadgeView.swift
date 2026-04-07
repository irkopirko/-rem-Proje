import SwiftUI

struct StatusBadgeView: View {
    let status: Assignment.Status

    var body: some View {
        Text(statusText)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch status {
        case .pending:            return "Bekliyor"
        case .submitted:          return "Gönderildi"
        case .reviewed:           return "Değerlendirildi"
        case .revisionRequested:  return "Revizyon İstendi"
        }
    }

    private var statusColor: Color {
        switch status {
        case .pending:            return .inkWarning
        case .submitted:          return Color.inkBlack
        case .reviewed:           return .inkSuccess
        case .revisionRequested:  return .inkError
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        StatusBadgeView(status: .pending)
        StatusBadgeView(status: .submitted)
        StatusBadgeView(status: .reviewed)
        StatusBadgeView(status: .revisionRequested)
    }
}
