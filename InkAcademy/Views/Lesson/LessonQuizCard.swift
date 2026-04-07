import SwiftUI

// MARK: - Quiz availability card

struct LessonQuizCard: View {
    let quiz: Quiz
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 14) {

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.inkSurfaceSecondary)
                    .frame(width: 44, height: 44)

                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.inkBlack)
            }

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text("Quiz")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.inkTextPrimary)

                Text("\(quiz.questions.count) soru · Geçme notu: \(quiz.passingScore)/\(quiz.questions.count)")
                    .font(.caption2)
                    .foregroundStyle(Color.inkTextTertiary)
            }

            Spacer()

            // Start button
            Button(action: onStart) {
                Text("Başla")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.inkWhite)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.inkBlack)
                    .clipShape(Capsule())
            }
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
    LessonQuizCard(
        quiz: Quiz(
            id: "1",
            lessonId: "lesson-1",
            questions: [
                Question(id: "q1", text: "Test?", options: ["A", "B"], correctOptionIndex: 0),
                Question(id: "q2", text: "Test?", options: ["A", "B"], correctOptionIndex: 1),
                Question(id: "q3", text: "Test?", options: ["A", "B"], correctOptionIndex: 0)
            ],
            passingScore: 2
        ),
        onStart: {}
    )
    .padding()
    .background(Color.inkBackground)
}
