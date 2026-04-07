import SwiftUI

// MARK: - Feedback Preview Card (latest instructor comment)

struct FeedbackPreviewCard: View {
    let feedback: Feedback
    let assignmentTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.inkIndigoSoft)
                        .frame(width: 40, height: 40)

                    Text(feedback.instructorInitials)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.inkIndigo)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(feedback.instructorName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.inkTextPrimary)

                    Text(assignmentTitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.inkTextTertiary)
                }

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.inkAccent)
                    Text("\(feedback.rating)/10")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.inkTextPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.inkAccentSoft)
                .clipShape(Capsule())
            }

            // Quote block
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.inkTeal)

                    Text("Eğitmen Notu")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.inkTextSecondary)
                }

                Text(feedback.comment)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.inkTextSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.inkSurfaceSecondary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous))

            HStack {
                Label(feedback.date.formatted_relative, systemImage: "clock")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkTextTertiary)

                Spacer()

                Label("Geri bildirim", systemImage: "bubble.left.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkGoldMuted)
            }
        }
    }

}

#Preview {
    FeedbackPreviewCard(
        feedback: Feedback(
            id: "1",
            assignmentId: "a1",
            instructorId: "i1",
            instructorName: "Eğitmen Elif Kaya",
            comment: "Çok detaylı ve kapsamlı bir rapor. Sterilizasyon bölümü özellikle başarılı.",
            rating: 9,
            date: .now.addingTimeInterval(-86400 * 2)
        ),
        assignmentTitle: "Hijyen Protokolü Raporu"
    )
    .padding(AppSpacing.cardInner)
    .premiumCard()
    .padding()
    .background(Color.inkBackground)
}