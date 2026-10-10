import SwiftUI

struct ChangePasswordView: View {
    let authService: AuthServiceProtocol

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var didSucceed = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Yeni şifren en az 6 karakter olmalı; büyük-küçük harf, rakam ve özel karakter kullanman önerilir.")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkTextSecondary)

                secureField(title: "Yeni şifre", text: $newPassword)
                secureField(title: "Yeni şifre (tekrar)", text: $confirmPassword)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.inkError)
                }

                InkButton(
                    title: isSaving ? "Kaydediliyor…" : "Şifreyi Güncelle",
                    isLoading: isSaving,
                    isDisabled: !canSave
                ) {
                    Task { await save() }
                }
            }
            .padding(AppSpacing.screenH)
            .padding(.vertical, AppSpacing.lg)
        }
        .inkPageBackground()
        .navigationTitle("Şifre Değiştir")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Şifre güncellendi", isPresented: $didSucceed) {
            Button("Tamam") { dismiss() }
        } message: {
            Text("Şifren başarıyla değiştirildi.")
        }
    }

    private var canSave: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }

    private func secureField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.inkTextTertiary)
            SecureField("••••••••", text: text)
                .padding(AppSpacing.md)
                .background(Color.inkSurface.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous))
        }
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            try await authService.changePassword(newPassword: newPassword)
            didSucceed = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
