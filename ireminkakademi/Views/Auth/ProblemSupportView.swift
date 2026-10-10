import SwiftUI

struct ProblemSupportView: View {
    @Binding var path: NavigationPath

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            Text("Hesabına girerken sorun yaşadığın için üzgünüz.")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(InkAuth.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            InkMockPrimaryButton(title: "Şifremi Unuttum") {
                path.append(AuthRoute.forgotPassword)
            }
            .padding(.top, 6)

            Text("Ya da")
                .font(.system(size: 14))
                .foregroundStyle(InkAuth.captionColor)

            InkMockPrimaryButton(title: "Bize Ulaş") {
                path.append(AuthRoute.contact)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, InkMockup.screenHorizontal)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inkMotionBackground()
    }
}
