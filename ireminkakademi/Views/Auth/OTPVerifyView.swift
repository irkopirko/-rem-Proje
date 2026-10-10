import SwiftUI

struct OTPVerifyView: View {
    let authService: AuthServiceProtocol
    let email: String
    let container: DIContainer

    @State private var digits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusIndex: Int?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()

            Image("inkakademi-logo")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .frame(maxWidth: .infinity)

            Text("Mail hesabına gönderdiğimiz kodu gir.")
                .font(.system(size: 15))
                .foregroundStyle(InkMockup.captionColor)

            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    TextField("", text: $digits[index])
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(InkMockup.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(InkMockup.fieldFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(InkMockup.fieldBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .focused($focusIndex, equals: index)
                        .onChange(of: digits[index]) { _, new in
                            let numeric = new.filter(\.isNumber)
                            if numeric != new { digits[index] = numeric }
                            if numeric.count > 1 { digits[index] = String(numeric.suffix(1)) }
                            if !numeric.isEmpty, index < 5 { focusIndex = index + 1 }
                        }
                }
            }

            if let localCode = (authService as? LocalAuthService)?.lastIssuedCode {
                Text("Geliştirme modu — sunucu bağlı değil. Onay kodun: \(localCode)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(InkMockup.captionColor)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkError)
            }

            InkMockPrimaryButton(title: isLoading ? "Doğrulanıyor…" : "Gönder", isLoading: isLoading) {
                Task { await verify() }
            }
            .padding(.top, 4)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, InkMockup.screenHorizontal)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inkMotionBackground()
        .onAppear { focusIndex = 0 }
    }

    private func verify() async {
        let code = digits.joined()
        guard code.count == 6 else {
            errorMessage = "6 haneli kodu gir."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await authService.registerVerify(email: email, code: code)
            container.completeLogin(user: user)
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}
