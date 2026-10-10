import Foundation
import UIKit

/// Crew panelinin ürün yönetimi.
protocol ProductAdminServicing {
    func fetchAll() async throws -> ProductsResponse
    func createCategory(name: String) async throws
    func deleteCategory(id: String) async throws
    func createProduct(_ draft: ProductDraft) async throws -> String
    func updateProduct(id: String, _ draft: ProductDraft) async throws
    func deleteProduct(id: String) async throws
    func uploadImage(productId: String, jpegData: Data) async throws -> ProductImageDTO
    func deleteImage(id: String) async throws
}

enum ProductAdminServiceFactory {
    static func make() -> ProductAdminServicing {
        if APIConfiguration.usesMockBackend || APIConfiguration.usesLocalAuth {
            return LocalProductStore.shared
        }
        return RemoteProductAdminService()
    }
}

enum ProductImageProcessor {
    /// Görseli en uzun kenarı 1600 px olacak şekilde küçültüp JPEG'e çevirir (sunucu sınırı 5 MB).
    static func jpegData(from data: Data, maxDimension: CGFloat = 1600, quality: CGFloat = 0.8) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.jpegData(compressionQuality: quality)
    }
}

final class RemoteProductAdminService: ProductAdminServicing {
    private let api = InkAPIClient.shared
    private struct OK: Decodable { let ok: Bool }
    private struct Created: Decodable { let id: String }

    func fetchAll() async throws -> ProductsResponse {
        try await api.request("/v1/crew/products", authorized: true)
    }

    func createCategory(name: String) async throws {
        struct Body: Encodable { let name: String }
        let _: Created = try await api.request("/v1/crew/products/category", method: "POST", body: Body(name: name), authorized: true)
    }

    func deleteCategory(id: String) async throws {
        let _: OK = try await api.request("/v1/crew/products/category/\(id)", method: "DELETE", authorized: true)
    }

    func createProduct(_ draft: ProductDraft) async throws -> String {
        let created: Created = try await api.request("/v1/crew/products", method: "POST", body: Body(draft), authorized: true)
        return created.id
    }

    func updateProduct(id: String, _ draft: ProductDraft) async throws {
        let _: OK = try await api.request("/v1/crew/products/\(id)", method: "PATCH", body: Body(draft), authorized: true)
    }

    func deleteProduct(id: String) async throws {
        let _: OK = try await api.request("/v1/crew/products/\(id)", method: "DELETE", authorized: true)
    }

    func uploadImage(productId: String, jpegData: Data) async throws -> ProductImageDTO {
        try await api.upload("/v1/crew/products/\(productId)/images", data: jpegData, contentType: "image/jpeg")
    }

    func deleteImage(id: String) async throws {
        let _: OK = try await api.request("/v1/crew/products/images/\(id)", method: "DELETE", authorized: true)
    }

    private struct Body: Encodable {
        let categoryId: String
        let name: String
        let explanation: String
        let purchaseUrl: String
        init(_ draft: ProductDraft) {
            categoryId = draft.categoryId
            name = draft.name
            explanation = draft.explanation
            purchaseUrl = draft.purchaseUrl
        }
    }
}

/// Sunucu bağlı değilken (Debug) crew'un eklediği ürünleri cihazda saklar; öğrenci ekranı da buradan okur.
final class LocalProductStore: ProductAdminServicing {
    static let shared = LocalProductStore()

    private struct StoredCategory: Codable { var id: String; var name: String }
    private struct StoredProduct: Codable {
        var id: String
        var categoryId: String
        var name: String
        var explanation: String
        var purchaseUrl: String
        var imageFiles: [String]
    }
    private struct Store: Codable {
        var categories: [StoredCategory] = []
        var products: [StoredProduct] = []
    }

    private let directory: URL
    private let storeURL: URL
    private let imagesDirectory: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("LocalProducts", isDirectory: true)
        storeURL = directory.appendingPathComponent("products.json")
        imagesDirectory = directory.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    func fetchAll() async throws -> ProductsResponse {
        let store = load()
        return ProductsResponse(
            categories: store.categories.map { ProductCategoryDTO(id: $0.id, name: $0.name, imageUrl: nil) },
            products: store.products.map { product in
                ProductDTO(
                    id: product.id,
                    categoryId: product.categoryId,
                    name: product.name,
                    imageUrl: nil,
                    explanation: product.explanation,
                    purchaseUrl: product.purchaseUrl,
                    images: product.imageFiles.map { file in
                        ProductImageDTO(id: file, url: imagesDirectory.appendingPathComponent(file).absoluteString)
                    },
                    isPublished: true
                )
            }
        )
    }

    func createCategory(name: String) async throws {
        var store = load()
        store.categories.append(StoredCategory(id: UUID().uuidString, name: name))
        save(store)
    }

    func deleteCategory(id: String) async throws {
        var store = load()
        for product in store.products where product.categoryId == id {
            removeFiles(product.imageFiles)
        }
        store.products.removeAll { $0.categoryId == id }
        store.categories.removeAll { $0.id == id }
        save(store)
    }

    func createProduct(_ draft: ProductDraft) async throws -> String {
        var store = load()
        let id = UUID().uuidString
        store.products.append(StoredProduct(
            id: id,
            categoryId: draft.categoryId,
            name: draft.name,
            explanation: draft.explanation,
            purchaseUrl: draft.purchaseUrl,
            imageFiles: []
        ))
        save(store)
        return id
    }

    func updateProduct(id: String, _ draft: ProductDraft) async throws {
        var store = load()
        guard let index = store.products.firstIndex(where: { $0.id == id }) else { return }
        store.products[index].categoryId = draft.categoryId
        store.products[index].name = draft.name
        store.products[index].explanation = draft.explanation
        store.products[index].purchaseUrl = draft.purchaseUrl
        save(store)
    }

    func deleteProduct(id: String) async throws {
        var store = load()
        if let product = store.products.first(where: { $0.id == id }) {
            removeFiles(product.imageFiles)
        }
        store.products.removeAll { $0.id == id }
        save(store)
    }

    func uploadImage(productId: String, jpegData: Data) async throws -> ProductImageDTO {
        var store = load()
        guard let index = store.products.firstIndex(where: { $0.id == productId }) else {
            throw InkAPIError.server("Not found")
        }
        let file = "\(UUID().uuidString).jpg"
        let url = imagesDirectory.appendingPathComponent(file)
        try jpegData.write(to: url, options: [.atomic, .completeFileProtection])
        store.products[index].imageFiles.append(file)
        save(store)
        return ProductImageDTO(id: file, url: url.absoluteString)
    }

    func deleteImage(id: String) async throws {
        var store = load()
        for index in store.products.indices {
            store.products[index].imageFiles.removeAll { $0 == id }
        }
        removeFiles([id])
        save(store)
    }

    private func removeFiles(_ files: [String]) {
        for file in files {
            try? FileManager.default.removeItem(at: imagesDirectory.appendingPathComponent(file))
        }
    }

    private func load() -> Store {
        guard let data = try? Data(contentsOf: storeURL),
              let store = try? JSONDecoder().decode(Store.self, from: data) else { return Store() }
        return store
    }

    private func save(_ store: Store) {
        if let data = try? JSONEncoder().encode(store) {
            try? data.write(to: storeURL, options: [.atomic, .completeFileProtection])
        }
    }
}
