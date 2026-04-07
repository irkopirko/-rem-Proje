import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(Color.inkSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous)
                    .stroke(Color.inkBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: AppShadows.cardRadius, x: 0, y: AppShadows.cardY)
    }

    func loadingOverlay(isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    func sectionHeader() -> some View {
        self
            .font(AppFont.sectionTitle())
            .foregroundStyle(Color.inkTextPrimary)
    }
}