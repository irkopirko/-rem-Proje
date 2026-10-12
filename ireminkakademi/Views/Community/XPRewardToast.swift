import SwiftUI

@Observable
final class XPToastStore {
    static let shared = XPToastStore()
    var amount: Int?

    func present(_ awarded: Int?) {
        guard let awarded, awarded > 0 else { return }
        amount = awarded
    }

    func dismiss() {
        amount = nil
    }
}

struct XPRewardToast: View {
    let amount: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(InkMockup.accentPink)
            Text("+\(amount) XP")
                .font(AppTypography.monoMedium(size: 16))
                .tracking(1.2)
                .foregroundStyle(InkMockup.textPrimary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassChrome(radius: 22, emphasized: true)
        .shadow(color: InkGlass.rose.opacity(0.28), radius: 16, y: 6)
        .allowsHitTesting(false)
        .accessibilityLabel("\(amount) deneyim puanı kazandın")
        .transition(reduceMotion ? .opacity : .scale(scale: 0.86).combined(with: .opacity).combined(with: .move(edge: .top)))
    }
}

struct XPToastHost: ViewModifier {
    @State private var store = XPToastStore.shared
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if visible, let amount = store.amount {
                    XPRewardToast(amount: amount)
                        .padding(.top, 10)
                }
            }
            .onChange(of: store.amount) { _, amount in
                guard amount != nil else {
                    visible = false
                    return
                }
                withAnimation(.spring(duration: 0.38, bounce: 0.22)) { visible = true }
                Task {
                    try? await Task.sleep(for: .milliseconds(1700))
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.28)) { visible = false }
                    }
                    try? await Task.sleep(for: .milliseconds(280))
                    store.dismiss()
                }
            }
    }
}

extension View {
    func xpToastHost() -> some View {
        modifier(XPToastHost())
    }
}
