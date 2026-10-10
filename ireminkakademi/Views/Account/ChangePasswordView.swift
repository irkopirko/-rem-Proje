import SwiftUI

struct ChangePasswordView: View {
    let authService: AuthServiceProtocol

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var didSucceed = false

    var body: some View {
        Form {
            Section {
                Text("Şifre büyük-küçük harf, rakam ve +,-,*,! içermelidir.")
                    .font(.caption)
                    .foregroundStyle(Color.inkTextSecondary)
            }
            SecureField("Mevcut şifre", text: $currentPassword)
            SecureField("Yeni şifre", text: $newPassword)
            SecureField("Yeni şifre (tekrar)", text: $confirmPassword)

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(Color.inkError)
            }

            Button(isSaving ? "Kaydediliyor…" : "Şifreyi Güncelle") {
                Task { await save() }
            }
            .disabled(!canSave || isSaving)
        }
        .navigationTitle("Şifre Değiştir")
        .alert("Şifre güncellendi", isPresented: $didSucceed) {
            Button("Tamam", role: .cancel) {}
        }
    }

    private var canSave: Bool {
        !currentPassword.isEmpty && newPassword == confirmPassword && newPassword.count >= 8
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await authService.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            didSucceed = true
        } catch {
            errorMessage = "Şifre güncellenemedi. Kuralları ve mevcut şifreni kontrol et."
        }
    }
}
