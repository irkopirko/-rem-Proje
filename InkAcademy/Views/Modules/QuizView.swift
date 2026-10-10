import SwiftUI

struct QuizView: View {
    @Bindable var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var lastQuestionIndex = 0

    var body: some View {
        Group {
            if viewModel.isSubmitted {
                QuizResultView(
                    viewModel: viewModel,
                    onRetry: { viewModel.retry() },
                    onClose: { dismiss() }
                )
            } else {
                questionContent
            }
        }
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Kapat") { dismiss() }
                    .font(.subheadline)
                    .foregroundStyle(Color.inkTextSecondary)
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
    }

    // MARK: - Question Content

    private var questionContent: some View {
        VStack(spacing: 0) {
            if let question = viewModel.currentQuestion {
                // Progress bar
                VStack(alignment: .leading, spacing: 14) {
                    Text("Bilgi Kontrolü")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.inkTextPrimary)

                    QuizProgressBar(
                        current: viewModel.currentQuestionIndex,
                        total: viewModel.totalQuestions
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)

                ScrollView {
                    QuizTransitionContainer(
                        id: viewModel.currentQuestionIndex,
                        direction: transitionDirection
                    ) {
                        VStack(alignment: .leading, spacing: 28) {

                            // Question type badge
                            HStack {
                                typeBadge(for: question)
                                Spacer()
                            }

                            // Question text
                            Text(question.text)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.inkTextPrimary)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)

                            // Options
                            VStack(spacing: 10) {
                                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                    QuizOptionButton(
                                        label: option,
                                        index: index,
                                        isSelected: viewModel.currentSelectedAnswer == index,
                                        isTrueFalse: question.isTrueFalse
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            viewModel.selectAnswer(index)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }

                // Navigation buttons
                navigationBar
            } else {
                ContentUnavailableView(
                    "Soru bulunamadı",
                    systemImage: "questionmark.circle",
                    description: Text("Bu quiz icin soru bulunamadi.")
                )
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .background(Color.inkBackground)
        .onChange(of: viewModel.currentQuestionIndex) { _, newValue in
            lastQuestionIndex = newValue
        }
    }

    // MARK: - Type Badge

    private func typeBadge(for question: Question) -> some View {
        HStack(spacing: 5) {
            Image(systemName: question.typeBadgeIcon)
                .font(.system(size: 10, weight: .semibold))
            Text(question.displayTypeLabel)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(Color.inkTextTertiary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.inkSurfaceSecondary)
        .clipShape(Capsule())
    }

    private var transitionDirection: QuizTransitionDirection {
        viewModel.currentQuestionIndex >= lastQuestionIndex ? .forward : .backward
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 12) {

            // Previous
            if !viewModel.isFirstQuestion {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.previousQuestion()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Önceki")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundStyle(Color.inkTextPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.inkBorder, lineWidth: 1)
                    )
                }
            }

            // Next or Submit
            if viewModel.isLastQuestion {
                Button {
                    Task { await viewModel.submit() }
                } label: {
                    Text("Gönder")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.canSubmit ? Color.inkBlack : Color.inkTextTertiary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!viewModel.canSubmit)
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.nextQuestion()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Sonraki")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.inkBlack)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color.inkSurface
                .shadow(color: .black.opacity(0.04), radius: 8, y: -4)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QuizView(viewModel: QuizViewModel(
            quiz: Quiz(
                id: "1", lessonId: "l1",
                questions: [
                    Question(id: "q1", text: "Dövme sanatının bilinen en eski örnekleri hangi döneme aittir?", options: ["Ortaçağ", "Neolitik Dönem", "Rönesans", "19. Yüzyıl"], correctOptionIndex: 1),
                    Question(id: "q2", text: "Otoklav sterilizasyon için kullanılır.", options: ["Doğru", "Yanlış"], correctOptionIndex: 0, type: .trueFalse),
                    Question(id: "q3", text: "Modern dövme makinesinin icadı hangi yüzyılda gerçekleşmiştir?", options: ["17. Yüzyıl", "18. Yüzyıl", "19. Yüzyıl", "20. Yüzyıl"], correctOptionIndex: 2)
                ],
                passingScore: 2
            ),
            moduleService: MockModuleService()
        ))
    }
}
