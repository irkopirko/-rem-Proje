import SwiftUI
import PhotosUI

struct CrewProductsView: View {
    private let service = ProductAdminServiceFactory.make()
    @State private var data: ProductsResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showNewCategory = false
    @State private var newCategoryName = ""
    @State private var categoryToDelete: ProductCategoryDTO?

    var body: some View {
        NavigationStack {
            List {
                if let data, data.categories.isEmpty {
                    ContentUnavailableView(
                        "Henüz kategori yok",
                        systemImage: "bag",
                        description: Text("Sağ üstten kategori ekleyip ürün eklemeye başlayabilirsin.")
                    )
                }

                ForEach(data?.categories ?? []) { category in
                    Section {
                        ForEach(products(in: category)) { product in
                            NavigationLink {
                                CrewProductEditorView(
                                    service: service,
                                    categories: data?.categories ?? [],
                                    existing: product,
                                    defaultCategoryId: category.id,
                                    onSaved: { Task { await load() } }
                                )
                            } label: {
                                productRow(product)
                            }
                        }
                        .onDelete { offsets in
                            let items = products(in: category)
                            Task {
                                for index in offsets { try? await service.deleteProduct(id: items[index].id) }
                                await load()
                            }
                        }

                        NavigationLink {
                            CrewProductEditorView(
                                service: service,
                                categories: data?.categories ?? [],
                                existing: nil,
                                defaultCategoryId: category.id,
                                onSaved: { Task { await load() } }
                            )
                        } label: {
                            Label("Ürün ekle", systemImage: "plus.circle.fill")
                                .foregroundStyle(Color.inkAccent)
                        }
                    } header: {
                        HStack {
                            Text(category.name)
                            Spacer()
                            Button(role: .destructive) {
                                categoryToDelete = category
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("\(category.name) kategorisini sil")
                        }
                    }
                }
            }
            .overlay { if isLoading && data == nil { ProgressView() } }
            .navigationTitle("Ürünler")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newCategoryName = ""
                        showNewCategory = true
                    } label: {
                        Label("Kategori ekle", systemImage: "folder.badge.plus")
                    }
                }
            }
            .refreshable { await load() }
            .task { await load() }
            .alert("Yeni kategori", isPresented: $showNewCategory) {
                TextField("Kategori adı", text: $newCategoryName)
                Button("Vazgeç", role: .cancel) {}
                Button("Ekle") { Task { await addCategory() } }
            }
            .confirmationDialog(
                "\"\(categoryToDelete?.name ?? "")\" kategorisi ve içindeki tüm ürünler silinecek.",
                isPresented: Binding(get: { categoryToDelete != nil }, set: { if !$0 { categoryToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Kategoriyi sil", role: .destructive) {
                    guard let category = categoryToDelete else { return }
                    Task {
                        try? await service.deleteCategory(id: category.id)
                        await load()
                    }
                }
            }
            .alert("Hata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func products(in category: ProductCategoryDTO) -> [ProductDTO] {
        (data?.products ?? []).filter { $0.categoryId == category.id }
    }

    private func productRow(_ product: ProductDTO) -> some View {
        HStack(spacing: 12) {
            ProductImageView(url: product.gallery.first?.resolvedURL)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(product.name).font(.system(size: 15, weight: .semibold))
                Text("\(product.gallery.count) görsel")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            data = try await service.fetchAll()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }

    private func addCategory() async {
        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            try await service.createCategory(name: name)
            await load()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}
