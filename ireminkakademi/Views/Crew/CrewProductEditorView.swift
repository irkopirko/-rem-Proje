import SwiftUI

struct CrewProductEditorView: View {
    let service: ProductAdminServicing
    let categories: [ProductCategoryDTO]
    let existing: ProductDTO?
    let defaultCategoryId: String
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var categoryId = ""
    @State private var name = ""
    @State private var explanation = ""
    @State private var purchaseUrl = ""
    @State private var images = CrewImageEditingModel()
    @State private var createdProductId: String?
    @State private var isSaving = false
    @State private var progressText: String?
    @State private var errorMessage: String?
    @State private var confirmDelete = false
    @State private var didLoad = false

    private static let explanationLimit = 5000

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CrewEditorSection(title: "Kategori") {
                    Picker("Kategori", selection: $categoryId) {
                        ForEach(categories) { Text($0.name).tag($0.id) }
                    }
                    .pickerStyle(.menu)
                    .tint(InkMockup.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                    .padding(.horizontal, 8)
                    .background(InkMockup.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                CrewEditorSection(title: "Ürün adı") {
                    CrewTextField(placeholder: "Örn. Cheyenne Sol Nova Unlimited", text: $name, font: .system(size: 18, weight: .semibold))
                }

                CrewEditorSection(title: "Açıklama", footer: "Özellikler, kullanım önerileri, neden tavsiye ettiğiniz… Öğrenci ürün sayfasında bu metni görür.") {
                    CrewLongTextEditor(
                        placeholder: "Ürünü detaylıca anlat…",
                        text: $explanation,
                        limit: Self.explanationLimit
                    )
                }

                CrewEditorSection(
                    title: "Görseller (\(images.totalCount)/\(CrewImageEditingModel.maxImages))",
                    footer: "İstediğin kadar fotoğraf seçebilirsin. İlk görsel kapak olarak gösterilir."
                ) {
                    CrewImageGrid(model: images)
                }

                CrewEditorSection(
                    title: "Ürün linki",
                    footer: "Öğrenciler ürün sayfasındaki \"Satın al\" düğmesine dokununca bu linke gider (ör. Shopier ürün linki). Linki kopyalayıp yapıştırman yeterli."
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        CrewTextField(placeholder: "https://www.shopier.com/…", text: $purchaseUrl, keyboard: .URL, autocapitalization: .never)
                            .autocorrectionDisabled()
                        if let url = ProductLink.normalized(purchaseUrl) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                Text(ProductLink.storeName(for: url))
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Link(destination: url) {
                                    Label("Linki test et", systemImage: "arrow.up.right.square")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                            }
                        } else if !trimmedUrl.isEmpty {
                            Label("Geçerli bir https linki gir.", systemImage: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.inkError)
                        }
                    }
                }

                if existing != nil {
                    Button("Ürünü sil", role: .destructive) { confirmDelete = true }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(existing == nil ? "Yeni ürün" : "Ürünü düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button("Kaydet") { Task { await save() } }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
        .overlay(alignment: .bottom) { CrewProgressBadge(text: progressText) }
        .disabled(isSaving)
        .onAppear(perform: populate)
        .confirmationDialog("Bu ürün kalıcı olarak silinecek.", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Ürünü sil", role: .destructive) { Task { await deleteProduct() } }
        }
        .alert("Kaydedilemedi", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var trimmedUrl: String { purchaseUrl.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !categoryId.isEmpty
            && ProductLink.normalized(purchaseUrl) != nil
            && explanation.count <= Self.explanationLimit
            && !images.isImporting
    }

    private func populate() {
        guard !didLoad else { return }
        didLoad = true
        categoryId = existing?.categoryId ?? defaultCategoryId
        name = existing?.name ?? ""
        explanation = existing?.explanation ?? ""
        purchaseUrl = existing?.purchaseUrl ?? ""
        images.existing = existing?.gallery ?? []
    }

    private func save() async {
        isSaving = true
        defer {
            isSaving = false
            progressText = nil
        }
        let draft = ProductDraft(
            categoryId: categoryId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            explanation: explanation.trimmingCharacters(in: .whitespacesAndNewlines),
            purchaseUrl: ProductLink.normalized(purchaseUrl)?.absoluteString ?? trimmedUrl
        )
        do {
            let productId: String
            if let id = createdProductId ?? existing?.id {
                try await service.updateProduct(id: id, draft)
                productId = id
            } else {
                productId = try await service.createProduct(draft)
                createdProductId = productId
            }
            try await images.commit(
                delete: { try await service.deleteImage(id: $0) },
                upload: { try await service.uploadImage(productId: productId, jpegData: $0) },
                progress: { progressText = "Görsel yükleniyor \($0)/\($1)" }
            )
            onSaved()
            dismiss()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }

    private func deleteProduct() async {
        guard let existing else { return }
        do {
            try await service.deleteProduct(id: existing.id)
            onSaved()
            dismiss()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}
