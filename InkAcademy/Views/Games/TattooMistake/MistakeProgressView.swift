import SwiftUI

struct MistakeProgressView: View {
    let found: Int
    let total: Int

    var body: some View {
        Text("Bulunan: \(found) / \(total)")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.inkTextSecondary)
            .accessibilityLabel("Bulunan hata \(found) bölü \(total)")
    }
}

#Preview {
    MistakeProgressView(found: 1, total: 3)
        .padding()
        .inkPageBackground()
}
