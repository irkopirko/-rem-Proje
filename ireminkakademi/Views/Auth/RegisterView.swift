import SwiftUI

struct RegisterView: View {
    let authService: AuthServiceProtocol
    @Binding var path: NavigationPath
    let container: DIContainer

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var usernameState: UsernameState = .idle
    @State private var email = ""
    @State private var password = ""
    @State private var passwordRepeat = ""
    @State private var day: Int?
    @State private var month: Int?
    @State private var year: Int?

    @State private var isLoading = false
    @State private var didAttemptSubmit = false
    @State private var errorMessage: String?

    private static let monthNames = [
        "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
        "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık",
    ]

    var body: some View {
        AuthFormLayout {
            VStack(alignment: .leading, spacing: 6) {
                Text("KAYIT OL")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(InkAuth.textPrimary)
                Text("Hayallerine birkaç adım.")
                    .font(.system(size: 15))
                    .foregroundStyle(InkAuth.captionColor)
                Text("Şimdi kaydol.")
                    .font(.system(size: 15))
                    .foregroundStyle(InkAuth.captionColor)
            }
            .padding(.bottom, 4)

            HStack(spacing: 12) {
                InkMockTextField(placeholder: "İsim", text: $firstName, invalid: showError(firstNameInvalid), textContentType: .givenName, autocapitalization: .words)
                InkMockTextField(placeholder: "Soyad", text: $lastName, invalid: showError(lastNameInvalid), textContentType: .familyName, autocapitalization: .words)
            }

            VStack(alignment: .leading, spacing: 6) {
                InkMockTextField(
                    placeholder: "Kullanıcı adı",
                    text: $username,
                    invalid: usernameShowsError,
                    textContentType: .username,
                    autocapitalization: .never
                )
                Text(usernameCaption)
                    .font(.system(size: 12))
                    .foregroundStyle(usernameCaptionColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .task(id: username) { await checkUsername() }

            InkMockTextField(
                placeholder: "E-mail",
                text: $email,
                invalid: showError(emailInvalid),
                textContentType: .emailAddress,
                keyboardType: .emailAddress,
                autocapitalization: .never
            )

            VStack(alignment: .leading, spacing: 6) {
                InkMockTextField(placeholder: "Şifre", text: $password, isSecure: true, invalid: showError(passwordInvalid), textContentType: .newPassword)
                Text("Şifre büyük ve küçük harf, rakam ve işaretlerden (+,-,*,!) oluşmalıdır. En az 8 karakter.")
                    .font(.system(size: 12))
                    .foregroundStyle(showError(passwordInvalid) ? Color.inkError : InkAuth.captionColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            InkMockTextField(placeholder: "Tekrar şifre", text: $passwordRepeat, isSecure: true, invalid: showError(passwordRepeatInvalid), textContentType: .newPassword)

            VStack(alignment: .leading, spacing: 6) {
                Text("Doğum tarihi")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(InkAuth.captionColor)
                HStack(spacing: 10) {
                    InkMockMenuPicker(title: "Gün", selection: $day, options: Array(1...31), invalid: showError(day == nil))
                    InkMockMenuPicker(
                        title: "Ay",
                        selection: $month,
                        options: Array(1...12),
                        label: { Self.monthNames[$0 - 1] },
                        invalid: showError(month == nil)
                    )
                    InkMockMenuPicker(title: "Yıl", selection: $year, options: yearOptions, invalid: showError(year == nil))
                }
            }

            InkMockPrimaryButton(title: isLoading ? "Gönderiliyor…" : "Kaydol", isLoading: isLoading) {
                Task { await submit() }
            }
            .padding(.top, 6)

            Button("Zaten hesabın var mı? Giriş yap.") {
                path.removeLast(path.count)
            }
            .font(.system(size: 13))
            .underline()
            .foregroundStyle(InkAuth.captionColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 12)
        }
        .inkImageBackground("image-background")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Kayıt tamamlanamadı", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private enum UsernameState: Equatable {
        case idle, checking, available, taken, unknown
    }

    private var usernameShowsError: Bool {
        if usernameState == .taken { return true }
        if !username.isEmpty && !UsernameRules.isValid(username) { return true }
        return showError(!UsernameRules.isValid(username))
    }

    private var usernameCaption: String {
        if !username.isEmpty && !UsernameRules.isValid(username) { return UsernameRules.caption }
        switch usernameState {
        case .checking: return "Kontrol ediliyor…"
        case .available: return "Bu kullanıcı adı kullanılabilir."
        case .taken: return "Bu kullanıcı adı alınmış. Başka bir tane dene."
        case .idle, .unknown: return UsernameRules.caption
        }
    }

    private var usernameCaptionColor: Color {
        if usernameShowsError { return .inkError }
        return usernameState == .available ? .inkSage : InkAuth.captionColor
    }

    private func checkUsername() async {
        usernameState = .idle
        guard UsernameRules.isValid(username) else { return }
        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled else { return }
        usernameState = .checking
        do {
            let available = try await authService.isUsernameAvailable(username)
            guard !Task.isCancelled else { return }
            usernameState = available ? .available : .taken
        } catch {
            guard !Task.isCancelled else { return }
            usernameState = .unknown
        }
    }

    private var yearOptions: [Int] {
        let current = Calendar.current.component(.year, from: .now)
        return Array((current - 90)...(current - 12)).reversed()
    }

    private var firstNameInvalid: Bool { firstName.trimmingCharacters(in: .whitespaces).isEmpty }
    private var lastNameInvalid: Bool { lastName.trimmingCharacters(in: .whitespaces).isEmpty }

    private var emailInvalid: Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.trimmingCharacters(in: .whitespaces).range(of: pattern, options: .regularExpression) == nil
    }

    private var passwordInvalid: Bool {
        let checks = [
            password.range(of: "[a-z]", options: .regularExpression) != nil,
            password.range(of: "[A-Z]", options: .regularExpression) != nil,
            password.range(of: "[0-9]", options: .regularExpression) != nil,
            password.range(of: "[+\\-*!]", options: .regularExpression) != nil,
            password.count >= 8,
        ]
        return !checks.allSatisfy { $0 }
    }

    private var passwordRepeatInvalid: Bool { passwordRepeat.isEmpty || passwordRepeat != password }

    private var birthDateString: String? {
        guard let day, let month, let year else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let date = Calendar.current.date(from: components),
              Calendar.current.component(.day, from: date) == day else { return nil }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private var formIsValid: Bool {
        !firstNameInvalid && !lastNameInvalid && UsernameRules.isValid(username) && usernameState != .taken && !emailInvalid
            && !passwordInvalid && !passwordRepeatInvalid && birthDateString != nil
    }

    private func showError(_ condition: Bool) -> Bool {
        didAttemptSubmit && condition
    }

    private func submit() async {
        didAttemptSubmit = true
        guard formIsValid, let birth = birthDateString else {
            if day != nil, month != nil, year != nil, birthDateString == nil {
                errorMessage = "Seçtiğin doğum tarihi geçerli değil."
            }
            return
        }

        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.registerStart(
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces),
                username: UsernameRules.normalize(username),
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                birthDate: birth
            )
            path.append(AuthRoute.otp(email: email.trimmingCharacters(in: .whitespaces).lowercased()))
        } catch {
            let message = AuthErrorMessage.from(error)
            if message == LocalAuthError.usernameTaken.errorDescription { usernameState = .taken }
            errorMessage = message
        }
    }
}
