import SwiftUI

struct MainTabView: View {
    let container: DIContainer

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Ana Sayfa", systemImage: "house.fill", value: 0) {
                HomeView(
                    viewModel: container.makeHomeViewModel(),
                    qrService: container.qrService,
                    accessManager: container.accessManager
                )
            }

            Tab("Modüller", systemImage: "book.fill", value: 1) {
                ModulesListView(
                    viewModel: container.makeModulesViewModel(),
                    accessManager: container.accessManager
                )
            }

            Tab("Ödevler", systemImage: "doc.text.fill", value: 2) {
                AssignmentsListView(viewModel: container.makeAssignmentsViewModel())
            }

            Tab("Ürünler", systemImage: "bag.fill", value: 3) {
                ProductsView()
            }

            Tab("Profil", systemImage: "person.fill", value: 4) {
                ProfileView(viewModel: container.makeProfileViewModel())
            }
        }
        .tint(Color.inkAccent)
    }
}