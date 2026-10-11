import SwiftUI

struct StudentMainTabView: View {
    let container: DIContainer
    @State private var tab: InkStudentTab = .home
    @State private var appearance = AppearanceSettings.shared
    @State private var unlocks = BadgeUnlockStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 88)
            }

            InkStudentTabBar(selection: $tab)
        }
        .overlay {
            if let badge = unlocks.presented {
                BadgeEarnedPopup(badge: badge) { unlocks.dismiss() }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .environment(\.inkStudioChrome, true)
        .preferredColorScheme(appearance.colorScheme)
        .task { await refreshBadges() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshBadges() } }
        }
    }

    private func refreshBadges() async {
        _ = try? await CatalogService().fetchBadgeProgress()
    }
}
