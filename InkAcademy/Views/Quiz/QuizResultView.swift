import SwiftUI

// MARK: - Quiz result summary with per-question review

struct QuizResultView: View {
    let viewModel: QuizViewModel
    let onRetry: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                // 1 — Hero result
                scoreHeader

                // 2 — Stats row
                statsRow

                // 3 — Per-question review
                reviewSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color.inkBackground)
    }

    // MARK: - Score Header

    private var scoreHeader: some View {
        VStack(spacing: 16) {

            // Icon
            ZStack {
                Circle()
                    .fill(viewModel.passed ? Color.inkGoldSoft : Color.inkError.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: viewModel.passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(viewModel.passed ? Color.inkGold : Color.inkError)
            }

            // Title
            Text(viewModel.passed ? "Quiz Tamamlandı" : "Başarısız")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.inkTextPrimary)

            // Subtitle
            Text(viewModel.passed
                 ? "Sonucun kaydedildi ve ilerlemen güncellendi."
                 : "Geçme notuna ulaşamadın. Tekrar dene."
            )
                .font(.subheadline)
                .foregroundStyle(Color.inkTextSecondary)
                .multilineTextAlignment(.center)

            // Buttons
            VStack(spacing: 10) {
                if !viewModel.passed {
                    retryButton
                }
                closeButton
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Puan", value: "\(viewModel.scorePercent)%", icon: "star.fill", accent: .inkGold)
            statCard(title: "Doğru", value: "\(viewModel.score)/\(viewModel.totalQuestions)", icon: "checkmark", accent: .inkSuccess)
            statCard(title: "Geçme Notu", value: "\(viewModel.quiz.passingScore)/\(viewModel.totalQuestions)", icon: "flag.fill", accent: .inkBlack)
        }
    }

    private func statCard(title: String, value: String, icon: String, accent: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(accent)

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkTextPrimary)

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.inkTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.14), lineWidth: 0.8)
        )
    }

    // MARK: - Review

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Soru Detayları")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.inkTextSecondary)

            ForEach(Array(viewModel.reviewItems.enumerated()), id: \.element.id) { index, item in
                reviewCard(item: item, number: index + 1)
            }
        }
    }

    private func reviewCard(item: ReviewItem, number: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            // Question
            HStack(alignment: .top, spacing: 10) {
                Text("\(number)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.inkTextTertiary)
                    .frame(width: 18, height: 18)
                    .background(Color.inkSurfaceSecondary)
                    .clipShape(Circle())

                Text(item.question.text)
                    .font(.subheadline)
                    .foregroundStyle(Color.inkTextPrimary)
                    .lineSpacing(3)
            }

            // Answer summary
            if item.isCorrect {
                QuizOptionReview(label: item.correctText, state: .correct)
            } else {
                if let selected = item.selectedText {
                    QuizOptionReview(label: selected, state: .wrong)
                }
                QuizOptionReview(label: item.correctText, state: .correctAnswer)
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

    // MARK: - Buttons

    private var retryButton: some View {
        Button(action: onRetry) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .semibold))
                Text("Tekrar Dene")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.inkGold)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Text("Kapat")
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(Color.inkTextPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.inkBorder, lineWidth: 1)
                )
        }
    }
}

#Preview {
    let quiz = Quiz(
        id: "1", lessonId: "l1",
        questions: [
            Question(id: "q1", text: "Test soru 1?", options: ["A", "B", "C", "D"], correctOptionIndex: 1),
            Question(id: "q2", text: "Test soru 2?", options: ["A", "B", "C", "D"], correctOptionIndex: 0),
            Question(id: "q3", text: "Test soru 3?", options: ["Doğru", "Yanlış"], correctOptionIndex: 0, type: .trueFalse)
        ],
        passingScore: 2
    )
    let vm = QuizViewModel(quiz: quiz, moduleService: MockModuleService())
    // Simulate submission
    vm.selectedAnswers = [1, 2, 0]
    vm.isSubmitted = true
    vm.score = 2

    return QuizResultView(viewModel: vm, onRetry: {}, onClose: {})
}
