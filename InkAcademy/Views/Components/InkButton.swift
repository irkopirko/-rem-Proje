import SwiftUI

// MARK: - Primary filled button (orange accent, white text)

struct InkButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                }
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isDisabled ? Color.inkTextTertiary : Color.inkAccent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous))
        }
        .disabled(isLoading || isDisabled)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Secondary outline button

struct InkButtonOutline: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(Color.inkTextPrimary)
                        .scaleEffect(0.85)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(Color.inkTextPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                    .stroke(Color.inkBorder, lineWidth: 1.5)
            )
        }
        .disabled(isLoading)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Subtle scale feedback

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        InkButton(title: "Giriş Yap") {}
        InkButton(title: "Yükleniyor...", isLoading: true) {}
        InkButton(title: "Devre dışı", isDisabled: true) {}
        InkButtonOutline(title: "Hesap Oluştur") {}
    }
    .padding()
    .background(Color.inkBackground)
}