import SwiftUI

struct InkSecureField: View {
    let title: String
    @Binding var text: String
    var icon: String? = nil
    var textContentType: UITextContentType? = .password
    var errorMessage: String? = nil

    @FocusState private var isFocused: Bool
    @State private var isRevealed = false

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

                Group {
                    if isRevealed {
                        TextField(title, text: $text)
                    } else {
                        SecureField(title, text: $text)
                    }
                }
                .font(.body)
                .foregroundStyle(Color.inkTextPrimary)
                .textContentType(textContentType)
                .textInputAutocapitalization(.never)
                .focused($isFocused)

                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.body)
                        .foregroundStyle(Color.inkTextTertiary)
                }
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
        InkSecureField(title: "Şifre", text: .constant(""), icon: "lock")
        InkSecureField(title: "Şifre", text: .constant("123"), icon: "lock", errorMessage: "En az 6 karakter")
    }
    .padding()
}
