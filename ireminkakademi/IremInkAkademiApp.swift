import SwiftUI

@main
struct IremInkAkademiApp: App {
    @State private var container = DIContainer()

    init() {
        URLCache.shared = URLCache(memoryCapacity: 16 * 1024 * 1024, diskCapacity: 64 * 1024 * 1024)
        AppFontRegistry.registerIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .task {
                    await container.bootstrapSession()
                }
        }
    }
}

struct RootView: View {
    let container: DIContainer

    var body: some View {
        Group {
            if container.router.phase == .welcome {
                WelcomeView(router: container.router)
            } else if !container.router.isAuthenticated {
                AuthFlowView(container: container)
            } else if container.sessionUser?.role == .superAdmin {
                SuperAdminRootView(container: container)
            } else if container.sessionUser?.role == .crew {
                CrewRootView(container: container)
            } else {
                StudentMainTabView(container: container)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: container.router.isAuthenticated)
        .preferredColorScheme(.light)
    }
}
