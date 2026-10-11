import SwiftUI

enum InkStudentTab: Int, CaseIterable {
    case home, modules, homework, shop, account

    var normalIcon: String {
        switch self {
        case .home: return "TabHomeNormal"
        case .modules: return "TabModuleNormal"
        case .homework: return "TabHomeworkNormal"
        case .shop: return "TabShopNormal"
        case .account: return "TabAccountNormal"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "TabHomeSelected"
        case .modules: return "TabModuleSelected"
        case .homework: return "TabHomeworkSelected"
        case .shop: return "TabShopSelected"
        case .account: return "TabAccountSelected"
        }
    }
}

struct InkStudentTabBar: View {
    @Binding var selection: InkStudentTab

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    private let iconSize: CGFloat = 30
    private let capsuleHeight: CGFloat = 70

    var body: some View {
        HStack(spacing: 0) {
            ForEach(InkStudentTab.allCases, id: \.rawValue) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: capsuleHeight)
        .background { capsuleChrome }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .accessibilityElement(children: .contain)
    }

    private func tabButton(_ tab: InkStudentTab) -> some View {
        let isActive = selection == tab
        return Button {
            select(tab)
        } label: {
            ZStack {
                Circle()
                    .fill(InkGlass.rose.opacity(isActive ? 0.14 : 0))
                    .frame(width: 44, height: 44)
                Image(isActive ? tab.selectedIcon : tab.normalIcon)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .opacity(isActive ? 1 : 0.55)
                    .shadow(color: isActive ? InkGlass.rose.opacity(0.32) : .clear, radius: 7, y: 0)
            }
            .frame(maxWidth: .infinity)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityLabel(accessibilityLabel(for: tab))
            .accessibilityAddTraits(isActive ? .isSelected : [])
        }
        .buttonStyle(.plain)
    }

    private func select(_ tab: InkStudentTab) {
        guard tab != selection else { return }
        if reduceMotion {
            selection = tab
        } else {
            withAnimation(.easeInOut(duration: 0.24)) {
                selection = tab
            }
        }
    }

    @ViewBuilder
    private var capsuleChrome: some View {
        let shape = Capsule(style: .continuous)
        let isDark = colorScheme == .dark
        ZStack {
            if reduceTransparency {
                shape.fill(InkGlass.surface.opacity(0.94))
            } else {
                shape.fill(.ultraThinMaterial)
                shape.fill(InkGlass.surface.opacity(isDark ? 0.38 : 0.55))
                shape.fill(
                    RadialGradient(
                        colors: [InkGlass.rose.opacity(isDark ? 0.12 : 0.08), InkGlass.burgundy.opacity(isDark ? 0.10 : 0.05), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 220
                    )
                )
            }
            shape.fill(
                LinearGradient(
                    colors: [Color.white.opacity(isDark ? 0.10 : 0.45), .clear, Color.black.opacity(isDark ? 0.16 : 0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            shape.stroke(InkGlass.border, lineWidth: 0.8)
        }
        .clipShape(shape)
        .shadow(color: Color.black.opacity(isDark ? 0.38 : 0.12), radius: 16, x: 0, y: 8)
        .shadow(color: InkGlass.rose.opacity(0.08), radius: 10, x: 0, y: 2)
        .allowsHitTesting(false)
    }

    private func accessibilityLabel(for tab: InkStudentTab) -> String {
        switch tab {
        case .home: return "Ana Sayfa"
        case .modules: return "Eğitimler"
        case .homework: return "Ödevler"
        case .shop: return "Ürünler"
        case .account: return "Hesabım"
        }
    }
}
