import SwiftUI

struct ErrorBannerView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
            Text(message)
                .font(.caption)
        }
        .foregroundStyle(Color.inkError)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.inkError.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.inkError.opacity(0.2), lineWidth: 0.5)
        )
    }
}

#Preview {
    ErrorBannerView(message: "Bir hata oluştu. Lütfen tekrar deneyin.")
        .padding()
}
