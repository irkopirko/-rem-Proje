import SwiftUI

private struct ShopCategoryPage: Identifiable, Hashable {
    let id: String
    let title: String
    let coverUrl: String?
    let products: [ProductDTO]

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct ProductsListView: View {
    let container: DIContainer
    @State private var catalog = CatalogService()
    @State private var pages: [ShopCategoryPage] = []
    @State private var loadError: String?
    @State private var isLoading = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    InkMockSectionTitle(text: "Ürünler")

                    if pages.isEmpty {
                        if let loadError {
                            shopMessage(loadError)
                        } else if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else {
                            shopMessage("Henüz yayınlanmış ürün kategorisi yok.")
                        }
                    } else {
                        ForEach(pages) { page in
                            NavigationLink(value: page.id) {
                                ProductCategoryCard(page: page)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .studentScreenBackground()
            .scrollBounceBehavior(.always)
            .navigationBarHidden(true)
            .refreshable { await load() }
            .navigationDestination(for: String.self) { categoryId in
                if let page = pages.first(where: { $0.id == categoryId }) {
                    ProductCategoryDetailView(title: page.title, products: page.products)
                }
            }
            .navigationDestination(for: ProductDTO.self) { product in
                ProductDetailView(product: product)
            }
            .task { if pages.isEmpty { await load() } }
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await catalog.fetchProducts()
            pages = data.categories.map { category in
                ShopCategoryPage(
                    id: category.id.trimmingCharacters(in: .whitespacesAndNewlines),
                    title: category.name,
                    coverUrl: category.imageUrl,
                    products: category.products ?? []
                )
            }
            .filter { !$0.id.isEmpty }
            loadError = nil
        } catch {
            if pages.isEmpty { loadError = error.localizedDescription }
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

private struct ProductCategoryCard: View {
    let page: ShopCategoryPage

    var body: some View {
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
                Text(AppTypography.turkishUppercased(page.title))
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

    private var coverURL: URL? {
        if let raw = page.coverUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
            if raw.hasPrefix("http://") || raw.hasPrefix("https://") || raw.hasPrefix("file://") {
                return URL(string: raw)
            }
            return URL(string: raw, relativeTo: APIConfiguration.baseURL)?.absoluteURL
        }
        return page.products.first { !$0.gallery.isEmpty }?.gallery.first?.resolvedURL
    }
}

struct ProductCategoryDetailView: View {
    let title: String
    let products: [ProductDTO]

    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(AppTypography.turkishUppercased(title))
                    .font(AppTypography.sectionHeading(size: 24))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if products.isEmpty {
                    Text("Bu kategoride henüz ürün yok.")
                        .font(AppTypography.body())
                        .foregroundStyle(InkMockup.captionColor)
                        .padding(.vertical, 16)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(products) { product in
                            NavigationLink(value: product) {
                                ProductGridItem(product: product)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .studentScreenBackground()
        .scrollBounceBehavior(.always)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProductGridItem: View {
    let product: ProductDTO

    var body: some View {
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
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .studentScreenBackground()
        .scrollBounceBehavior(.always)
        .navigationBarTitleDisplayMode(.inline)
    }
}
