import SwiftUI

struct StudentMainTabView: View {
    let container: DIContainer
    @State private var tab: InkStudentTab = .home
    @State private var hidesTabBar = false
    @State private var appearance = AppearanceSettings.shared
    @State private var unlocks = BadgeUnlockStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:
                    HomeView(container: container, hidesTabBar: $hidesTabBar)
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
                Color.clear.frame(height: hidesTabBar ? 0 : 88)
            }

            if !hidesTabBar {
                InkStudentTabBar(selection: $tab)
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

    private func refreshBadges() async {
        _ = try? await CatalogService().fetchBadgeProgress()
    }
}
