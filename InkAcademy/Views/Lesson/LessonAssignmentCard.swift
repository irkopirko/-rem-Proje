import SwiftUI

// MARK: - Related assignment card

struct LessonAssignmentCard: View {
    let assignment: Assignment

    var body: some View {
        HStack(spacing: 14) {

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.inkSurfaceSecondary)
                    .frame(width: 44, height: 44)

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.inkTextSecondary)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.inkTextPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    StatusBadgeView(status: assignment.status)

                    Text("Teslim: \(assignment.dueDate.formatted_ddMMyyyy)")
                        .font(.caption2)
                        .foregroundStyle(Color.inkTextTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.inkTextTertiary)
        }
        .padding(16)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.inkDivider, lineWidth: 0.5)
        )
    }
}

#Preview {
    LessonAssignmentCard(
        assignment: Assignment(
            id: "1",
            title: "İlk Dövme Tasarımı",
            description: "Basit bir tasarım çizin.",
            dueDate: .now.addingTimeInterval(86400 * 5),
            submissionDate: nil,
            fileURL: nil,
            status: .pending,
            feedback: nil
        )
    )
    .padding()
    .background(Color.inkBackground)
}
