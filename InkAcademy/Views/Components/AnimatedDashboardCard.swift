import SwiftUI

struct AnimatedDashboardCard<Content: View>: View {
    let delay: Double
    let content: Content

    @State private var isVisible = false

    init(delay: Double = 0, @ViewBuilder content: () -> Content) {
        self.delay = delay
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.cardInner)
            .background(Color.inkSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous)
                    .stroke(Color.inkBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: AppShadows.cardRadius, x: 0, y: AppShadows.cardY)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.985)
            .offset(y: isVisible ? 0 : 6)
            .animation(.easeOut(duration: 0.35).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

#Preview {
    AnimatedDashboardCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Örnek Kart")
                .font(.subheadline.weight(.semibold))
            Text("Kısa açıklama metni")
                .font(.caption)
                .foregroundStyle(Color.inkTextSecondary)
        }
    }
    .padding()
    .background(Color.inkBackground)
}