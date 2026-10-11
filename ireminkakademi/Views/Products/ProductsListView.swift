import SwiftUI

private enum ShopRoute: Hashable {
    case category(String)
    case product(String)
}

struct ProductsListView: View {
    let container: DIContainer
    @State private var catalog = CatalogService()
    @State private var data: ProductsResponse?
    @State private var loadError: String?
    @State private var isLoading = false
    @State private var path: [ShopRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    InkMockSectionTitle(text: "Ürünler")

                    if let categories = data?.categories {
                        if categories.isEmpty {
                            shopMessage("Henüz yayınlanmış ürün kategorisi yok.")
                        }
                        ForEach(categories, id: \.id) { category in
                            ProductCategoryRow(
                                category: category,
                                products: products(in: category.id),
                                onOpen: { path.append(.category($0)) }
                            )
                        }
                    } else if let loadError {
                        shopMessage(loadError)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .studentScreenBackground()
            .navigationBarHidden(true)
            .refreshable { await load() }
            .navigationDestination(for: ShopRoute.self) { route in
                switch route {
                case .category(let id):
                    if let category = data?.categories.first(where: { $0.id == id }) {
                        ProductCategoryDetailView(category: category, products: products(in: id)) { productId in
                            path.append(.product(productId))
                        }
                    } else {
                        shopMessage("Kategori bulunamadı.")
                    }
                case .product(let id):
                    if let product = data?.products.first(where: { $0.id == id }) {
                        ProductDetailView(product: product)
                    } else {
                        shopMessage("Ürün bulunamadı.")
                    }
                }
            }
            .task { if data == nil { await load() } }
        }
    }

    private func products(in categoryId: String) -> [ProductDTO] {
        let needle = categoryId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return (data?.products ?? []).filter {
            $0.categoryId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == needle
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            data = try await catalog.fetchProducts()
            loadError = nil
        } catch {
            if data == nil { loadError = error.localizedDescription }
        }
    }

    private func shopMessage(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.body())
            .foregroundStyle(InkMockup.captionColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 24)
    }
}

private struct ProductCategoryRow: View {
    let category: ProductCategoryDTO
    let products: [ProductDTO]
    let onOpen: (String) -> Void

    var body: some View {
        Button {
            onOpen(category.id)
        } label: {
            Color.clear
                .frame(height: 128)
                .overlay {
                    if let coverURL {
                        ProductImageView(url: coverURL)
                            .overlay(LinearGradient(colors: [.clear, InkGlass.background.opacity(0.82)], startPoint: .center, endPoint: .bottom))
                    } else {
                        InkMockup.cardFill
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    Text(AppTypography.turkishUppercased(category.name))
                        .font(AppTypography.cardTitle())
                        .tracking(0.8)
                        .foregroundStyle(InkMockup.textPrimary)
                        .padding(16)
                }
                .clipShape(RoundedRectangle(cornerRadius: InkMockup.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: InkMockup.cardRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
    }

    private var coverURL: URL? {
        if let raw = category.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
            if raw.hasPrefix("http://") || raw.hasPrefix("https://") || raw.hasPrefix("file://") {
                return URL(string: raw)
            }
            return URL(string: raw, relativeTo: APIConfiguration.baseURL)?.absoluteURL
        }
        return products.first { !$0.gallery.isEmpty }?.gallery.first?.resolvedURL
    }
}

struct ProductCategoryDetailView: View {
    let category: ProductCategoryDTO
    let products: [ProductDTO]
    var onOpenProduct: (String) -> Void = { _ in }

    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(AppTypography.turkishUppercased(category.name))
                    .font(AppTypography.sectionHeading(size: 24))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if products.isEmpty {
                    Text("Bu kategoride henüz ürün yok.")
                        .font(AppTypography.body())
                        .foregroundStyle(InkMockup.captionColor)
                        .padding(.vertical, 16)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(products, id: \.id) { product in
                            ProductGridItem(product: product, onOpen: onOpenProduct)
                        }
                    }
                }
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .studentScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProductGridItem: View {
    let product: ProductDTO
    let onOpen: (String) -> Void

    var body: some View {
        Button {
            onOpen(product.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Color.clear
                    .frame(height: 140)
                    .overlay { ProductImageView(url: product.gallery.first?.resolvedURL) }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(product.name)
                    .font(AppTypography.cardTitle(size: 15))
                    .foregroundStyle(InkMockup.textPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ProductDetailView: View {
    let product: ProductDTO

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ProductGalleryView(images: product.gallery, height: 300)

                Text(product.name)
                    .font(AppTypography.sectionHeading())
                    .foregroundStyle(InkMockup.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)

                if let explanation = product.explanation, !explanation.isEmpty {
                        Text(explanation)
                        .font(AppTypography.body())
                        .foregroundStyle(InkMockup.captionColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let url = ProductLink.normalized(product.purchaseUrl) {
                    VStack(spacing: 8) {
                        Link(destination: url) {
                            HStack(spacing: 8) {
                                Text("SATIN AL")
                                Image(systemName: "arrow.up.right")
                            }
                            .font(AppTypography.button())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: InkMockup.buttonHeight)
                            .background {
                                glassFill(radius: InkGlass.smallRadius, emphasized: true, reduceTransparency: false, colorScheme: .dark)
                            }
                        }
                        Label("\(ProductLink.storeName(for: url)) üzerinden satın alırsın", systemImage: "lock.fill")
                            .font(AppTypography.caption())
                            .foregroundStyle(InkMockup.captionColor)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.vertical, 16)
        }
        .studentScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}
