import SwiftUI
import UIKit

/// Ürün görseli: sunucudaki görselleri ve geliştirme modundaki yerel dosyaları gösterir.
struct ProductImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
            if let url, url.isFileURL {
                if let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: contentMode)
                } else {
                    placeholder
                }
            } else if let url {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: contentMode)
                    case .failure:
                        placeholder
                    default:
                        ZStack { InkMockup.cardFill; ProgressView() }
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            InkMockup.cardFill
            Image(systemName: "photo")
                .font(.system(size: 26))
                .foregroundStyle(InkMockup.captionColor)
        }
    }
}

/// Kaydırmalı ürün görsel galerisi. TabView kullanmaz; dikey sayfa kaydırmasını bozmasın.
struct ProductGalleryView: View {
    let images: [ProductImageDTO]
    var height: CGFloat = 280

    var body: some View {
        Group {
            if images.isEmpty {
                ProductImageView(url: nil)
            } else if images.count == 1 {
                ProductImageView(url: images[0].resolvedURL)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                            ProductImageView(url: image.resolvedURL)
                                .containerRelativeFrame(.horizontal)
                                .frame(height: height)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
