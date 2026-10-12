import SwiftUI

struct StudentMainTabView: View {
    let container: DIContainer
    @State private var tab: InkStudentTab = .home
    @State private var hidesTabBar = false
    @State private var appearance = AppearanceSettings.shared
    @State private var unlocks = BadgeUnlockStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        tabRoot
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !hidesTabBar {
                    InkStudentTabBar(selection: $tab)
                        .padding(.top, 10)
                        .padding(.bottom, 2)
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
            .overlay {
                if let badge = unlocks.presented {
                    BadgeEarnedPopup(badge: badge) { unlocks.dismiss() }
                }
            }
            .xpToastHost()
            .environment(\.inkStudioChrome, true)
            .preferredColorScheme(appearance.colorScheme)
            .task { await refreshBadges() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await refreshBadges() } }
            }
    }

    @ViewBuilder
    private var tabRoot: some View {
        switch tab {
        case .home:
            HomeView(container: container, hidesTabBar: $hidesTabBar)
        case .modules:
            ModulesListView(container: container, hidesTabBar: $hidesTabBar)
        case .homework:
            AssignmentsListView(container: container)
        case .shop:
            ProductsListView(container: container)
        case .account:
            AccountTabView(container: container)
        }
    }

    private func refreshBadges() async {
        _ = try? await CatalogService().fetchBadgeProgress()
    }
}
