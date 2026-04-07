import SwiftUI

// MARK: - Live Lesson Card (placeholder for upcoming feature)

struct LiveLessonCard: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadii.sm, style: .continuous)
                    .fill(Color.inkSurfaceSecondary)
                    .frame(width: 44, height: 44)

                Image(systemName: "video.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.inkTextTertiary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Canlı Ders")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.inkTextPrimary)

                Text("Yakında aktif olacak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkTextTertiary)
            }

            Spacer()

            Text("Yakında")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.inkTextTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.inkSurfaceSecondary)
                .clipShape(Capsule())
        }
        .padding(AppSpacing.lg)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous)
                .stroke(Color.inkBorder, lineWidth: 1)
        )
        .opacity(0.6)
    }
}

#Preview {
    LiveLessonCard()
        .padding()
        .background(Color.inkBackground)
}