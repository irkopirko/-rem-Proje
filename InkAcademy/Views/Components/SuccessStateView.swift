import SwiftUI

struct SuccessStateView: View {
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var onAction: (() -> Void)? = nil

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.inkSuccess)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.inkTextPrimary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Color.inkTextTertiary)

                if let buttonTitle, let onAction {
                    Button(buttonTitle) { onAction() }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.inkBlack)
                        .padding(.top, 6)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.inkSuccess.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.inkSuccess.opacity(0.2), lineWidth: 0.5)
        )
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.98)
        .animation(.easeInOut(duration: 0.25), value: isVisible)
        .onAppear { isVisible = true }
    }
}

#Preview {
    SuccessStateView(
        title: "Ödev başarıyla gönderildi",
        message: "Eğitmeniniz değerlendirecektir"
    )
    .padding()
    .background(Color.inkBackground)
}
