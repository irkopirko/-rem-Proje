import SwiftUI

// MARK: - Settings-style key/value stat row

struct ProfileStatRow: View {
    let icon: String
    let title: String
    let value: String
    var iconColor: Color = .inkTextSecondary

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadii.sm, style: .continuous)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.inkTextPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.inkTextSecondary)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    VStack(spacing: 0) {
        ProfileStatRow(icon: "book.fill", title: "Tamamlanan Modül", value: "2/4", iconColor: .inkAccent)
        Divider().padding(.leading, 46)
        ProfileStatRow(icon: "checkmark.circle", title: "Tamamlanan Ders", value: "5/12", iconColor: .inkSuccess)
        Divider().padding(.leading, 46)
        ProfileStatRow(icon: "star.fill", title: "Ortalama Puan", value: "8.5/10", iconColor: .inkWarning)
    }
    .padding(16)
    .premiumCard()
    .padding()
    .background(Color.inkBackground)
}