import SwiftUI

struct PersonalInfoView: View {
    @Bindable var viewModel: AccountSettingsViewModel

    @State private var editedName: String = ""
    @State private var saveMessage: String?

    var body: some View {
        Form {
            Section {
                TextField("Ad Soyad", text: $editedName)
                    .textContentType(.name)
            } header: {
                Text("Kişisel Bilgiler")
            } footer: {
                Text("E-posta adresin güvenlik nedeniyle değiştirilemez. Değişiklik için destek ile iletişime geç.")
            }

            Section("Hesap") {
                LabeledContent("Kullanıcı adı", value: viewModel.username)
                LabeledContent("E-posta", value: viewModel.email)
                LabeledContent("Seviye", value: viewModel.levelTitle)
            }

            Section {
                Button("Kaydet") {
                    viewModel.userName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                    saveMessage = "Bilgiler yerel olarak güncellendi. Sunucu senkronu yakında."
                }
                .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .scrollContentBackground(.hidden)
        .inkPageBackground()
        .navigationTitle("Kişisel Bilgiler")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { editedName = viewModel.userName }
        .alert("Kaydedildi", isPresented: Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { saveMessage = nil }
        } message: {
            Text(saveMessage ?? "")
        }
    }
}
