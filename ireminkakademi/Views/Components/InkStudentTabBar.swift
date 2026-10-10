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

    var body: some View {
        HStack(spacing: 0) {
            ForEach(InkStudentTab.allCases, id: \.rawValue) { tab in
                Button {
                    selection = tab
                } label: {
                    Image(selection == tab ? tab.selectedIcon : tab.normalIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .accessibilityLabel(accessibilityLabel(for: tab))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(.ultraThinMaterial)
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
