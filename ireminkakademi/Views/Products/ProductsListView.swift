import SwiftUI

struct ProductsListView: View {
    let container: DIContainer
    @State private var catalog = CatalogService()
    @State private var data: ProductsResponse?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    InkMockSectionTitle(text: "Ürünler")

                    ForEach(data?.categories ?? []) { category in
                        NavigationLink {
                            ProductCategoryDetailView(
                                category: category,
                                products: (data?.products ?? []).filter { $0.categoryId == category.id }
                            )
                        } label: {
                            let cover = (data?.products ?? []).first { $0.categoryId == category.id && !$0.gallery.isEmpty }?.gallery.first
                            Color.clear
                                .frame(height: 128)
                                .overlay {
                                    if let cover {
                                        ProductImageView(url: cover.resolvedURL)
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
                }
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.top, 12)
            }
            .studentScreenBackground()
            .navigationBarHidden(true)
            .task { data = try? await catalog.fetchProducts() }
        }
    }
}

struct ProductCategoryDetailView: View {
    let category: ProductCategoryDTO
    let products: [ProductDTO]

    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(AppTypography.turkishUppercased(category.name))
                    .font(AppTypography.sectionHeading(size: 24))
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(products) { product in
                        NavigationLink {
                            ProductDetailView(product: product)
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
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.top, 12)
        }
        .studentScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
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
                                glassFill(radius: InkGlass.smallRadius, emphasized: true, reduceTransparency: false)
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
