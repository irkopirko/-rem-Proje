import Foundation

/// Kitaplık içerikleri — ileride `SupabaseEcosystemCatalogService` ile değiştirilebilir.
protocol EcosystemCatalogServing {
    func fetchProducts() async -> [InkProduct]
    func fetchPracticeTasks() async -> [PracticeTask]
    func fetchLiveSessions() async -> [LiveSession]
    func fetchCertificates() async -> [Certificate]
    func fetchSampleQuizzes() async -> [Quiz]
}
