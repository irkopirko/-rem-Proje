import SwiftUI
import AVKit

struct LessonDetailView: View {
    @Bindable var viewModel: LessonDetailViewModel
    @State private var showQuiz = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // 1 — Video player
                LessonVideoPlayerView(
                    player: viewModel.player,
                    duration: viewModel.lesson.formattedDuration
                )

                // 2 — Title + meta
                titleSection

                // 3 — Notes
                if let notes = viewModel.notes {
                    LessonNotesCard(text: notes)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // 4 — Quiz
                if let quiz = viewModel.quiz {
                    SectionHeaderView(text: "Quiz")
                    LessonQuizCard(quiz: quiz) {
                        showQuiz = true
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // 5 — Related assignment
                if let assignment = viewModel.relatedAssignment {
                    SectionHeaderView(text: "İlgili Ödev")
                    NavigationLink(value: assignment) {
                        LessonAssignmentCard(assignment: assignment)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // 6 — Mark complete
                completeSection
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isCompleted)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 40)
        }
        .background(Color.inkBackground)
        .navigationTitle("Ders Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadRelatedContent()
        }
        .onDisappear {
            viewModel.pauseVideo()
        }
        .sheet(isPresented: $showQuiz) {
            if let quiz = viewModel.quiz {
                NavigationStack {
                    QuizView(viewModel: QuizViewModel(
                        quiz: quiz,
                        moduleService: viewModel.moduleService
                    ))
                }
            }
        }
        .navigationDestination(for: Assignment.self) { assignment in
            AssignmentDetailView(
                assignment: assignment,
                viewModel: AssignmentsViewModel(assignmentService: viewModel.assignmentService)
            )
        }
    }

    // MARK: - 2. Title + Meta

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Completion badge + order
            HStack(spacing: 8) {
                Text("Ders \(viewModel.lesson.order)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.inkGold)
                    .tracking(0.4)

                if viewModel.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Tamamlandı")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(Color.inkSuccess)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.inkSuccess.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            // Title
            Text(viewModel.lesson.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.inkTextPrimary)

            if !viewModel.lesson.description.isEmpty {
                Text(viewModel.lesson.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.inkTextSecondary)
                    .lineSpacing(4)
            }

            // Meta row
            HStack(spacing: 14) {
                Label(viewModel.lesson.formattedDuration, systemImage: "clock")
                if viewModel.lesson.videoURL != nil {
                    Label("Video", systemImage: "play.fill")
                }
                if viewModel.quiz != nil {
                    Label("Quiz", systemImage: "questionmark.circle")
                }
            }
            .font(.caption)
            .foregroundStyle(Color.inkTextTertiary)
        }
    }

    // MARK: - 6. Complete

    @ViewBuilder
    private var completeSection: some View {
        if viewModel.isCompleted {
            // Already completed banner
            SuccessStateView(
                title: "Bu ders tamamlandı",
                message: "Bir sonraki derse geçebilirsin"
            )
        } else {
            // Mark complete button
            Button {
                Task { await viewModel.markComplete() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    }
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 15, weight: .medium))
                    Text("Dersi Tamamla")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.inkGold)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(viewModel.isLoading)

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.inkError)
            }
        }
    }

}

// MARK: - Preview

#Preview {
    NavigationStack {
        LessonDetailView(viewModel: LessonDetailViewModel(
            lesson: Lesson(
                id: "lesson-1-1",
                title: "Dövme Tarihçesi",
                videoURL: URL(string: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4"),
                duration: 720,
                order: 1,
                isCompleted: false,
                description: "Dövme sanatının dünya genelindeki tarihsel gelişimini keşfedin. Antik Mısır'dan Polinezya'ya, Japonya'dan modern Batı kültürüne kadar dövmenin toplumsal ve sanatsal anlamını inceleyin."
            ),
            moduleService: MockModuleService(),
            assignmentService: MockAssignmentService()
        ))
    }
}
