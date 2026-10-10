import SwiftUI

struct MainTabView: View {
    let container: DIContainer

    @State private var selectedTab: Int = 0
    @State private var homeViewModel: HomeViewModel
    @State private var profileViewModel: ProfileViewModel
    @State private var accountSettingsViewModel: AccountSettingsViewModel

    init(container: DIContainer) {
        self.container = container
        _homeViewModel = State(initialValue: container.makeHomeViewModel())
        _profileViewModel = State(initialValue: container.makeProfileViewModel())
        _accountSettingsViewModel = State(initialValue: container.makeAccountSettingsViewModel())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Ana Sayfa", systemImage: "house.fill", value: 0) {
                HomeView(
                    viewModel: homeViewModel,
                    qrService: container.qrService,
                    accessManager: container.accessManager,
                    moduleService: container.moduleService,
                    assignmentService: container.assignmentService,
                    ecosystem: container.ecosystemCatalog
                )
            }

            Tab("Modüller", systemImage: "book.fill", value: 1) {
                ModulesListView(
                    viewModel: container.makeModulesViewModel(),
                    accessManager: container.accessManager,
                    ecosystem: container.ecosystemCatalog
                )
            }

            Tab("Ödevler", systemImage: "doc.text.fill", value: 2) {
                AssignmentsListView(
                    viewModel: container.makeAssignmentsViewModel(),
                    ecosystem: container.ecosystemCatalog
                )
            }

            Tab("Ürünler", systemImage: "bag.fill", value: 3) {
                ProductsView(ecosystem: container.ecosystemCatalog)
            }

            Tab("Hesabım", systemImage: "person.fill", value: 4) {
                AccountSettingsView(
                    viewModel: accountSettingsViewModel,
                    authService: container.authService,
                    profileViewModel: profileViewModel,
                    userProgress: container.userProgress
                )
            }
        }
        .tint(Color.inkAccent)
    }
}
