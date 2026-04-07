import SwiftUI

struct SectionHeaderView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.inkTextSecondary)
            .tracking(0.3)
    }
}

#Preview {
    SectionHeaderView(text: "Bölüm Başlığı")
        .padding()
        .background(Color.inkBackground)
}