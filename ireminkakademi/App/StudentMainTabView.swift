import SwiftUI

struct StudentMainTabView: View {
    let container: DIContainer
    @State private var tab: InkStudentTab = .home

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case .home:
                    HomeView(container: container)
                case .modules:
                    ModulesListView(container: container)
                case .homework:
                    AssignmentsListView(container: container)
                case .shop:
                    ProductsListView(container: container)
                case .account:
                    AccountTabView(container: container)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            InkStudentTabBar(selection: $tab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
