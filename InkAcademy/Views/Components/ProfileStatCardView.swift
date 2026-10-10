import SwiftUI

struct ProfileStatCardView: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = .inkIndigo

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkTextSecondary)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkTextPrimary)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.inkBorder.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: 12) {
        ProfileStatCardView(icon: "play.rectangle.fill", title: "Tamamlanan video", value: "4", tint: .inkTeal)
        ProfileStatCardView(icon: "square.stack.3d.up.fill", title: "Tamamlanan modül", value: "2", tint: .inkAccent)
    }
    .padding()
    .background(Color(.systemGray6))
}
