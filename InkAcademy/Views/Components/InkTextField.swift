import SwiftUI

struct InkTextField: View {
    let title: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never
    var errorMessage: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.inkTextSecondary)

            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(isFocused ? Color.inkBlack : Color.inkTextTertiary)
                        .frame(width: 20)
                }

                TextField(title, text: $text)
                    .font(.body)
                    .foregroundStyle(Color.inkTextPrimary)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .focused($isFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.inkSurfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: isFocused ? 1.5 : 0.5)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundStyle(Color.inkError)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }

    private var borderColor: Color {
        if errorMessage != nil { return .inkError }
        return isFocused ? .inkBlack : .inkBorder
    }
}

#Preview {
    VStack(spacing: 20) {
        InkTextField(
            title: "E-posta",
            text: .constant(""),
            icon: "envelope",
            keyboardType: .emailAddress
        )
        InkTextField(
            title: "E-posta",
            text: .constant("test@test.com"),
            icon: "envelope",
            errorMessage: "Geçersiz e-posta adresi"
        )
    }
    .padding()
}
