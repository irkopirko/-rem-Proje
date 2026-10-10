import SwiftUI

struct WelcomeView: View {
    let router: AppRouter

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            HStack(spacing: 8) {
                Text("Powered by")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(InkAuth.captionColor)
                Image("remi-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 27)
            }

            Image("inkakademi-logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
                .accessibilityLabel("Ink Akademi")

            VStack(alignment: .leading, spacing: 5) {
                Text("Hayallerindeki dövmecilik kariyerin.")
                Text("Şimdi başla.")
            }
            .font(.system(size: 19))
            .foregroundStyle(InkAuth.captionColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 49)

            InkMockPrimaryButton(title: "Şimdi Katıl") {
                router.showAuth()
            }
            .padding(.top, 22)
        }
        .padding(.horizontal, InkMockup.screenHorizontal)
        .padding(.bottom, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inkMotionBackground()
    }
}

/// Siyah dolgu, beyaz yazılı mockup butonu.
struct InkPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: InkMockup.buttonHeight)
            .background(Color.black.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
