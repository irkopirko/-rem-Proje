import SwiftUI

struct ModuleDetailView: View {
    let module: TrainingModule
    let moduleService: ModuleServiceProtocol
    let assignmentService: AssignmentServiceProtocol

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                headerSection
                progressCard
                lessonsCard
            }
            .padding(.horizontal, AppSpacing.screenH)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(Color.inkBackground)
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Lesson.self) { lesson in
            LessonDetailView(viewModel: LessonDetailViewModel(
                lesson: lesson,
                moduleService: moduleService,
                assignmentService: assignmentService
            ))
        }
    }

    // MARK: - 1. Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadii.lg, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.inkTextPrimary, Color.inkGoldMuted],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 140)

                VStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color.inkAccentSoft)

                    Text(module.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }

            Text(module.description)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.inkTextSecondary)
                .lineSpacing(4)
        }
    }

    // MARK: - 2. Progress

    private var progressCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                AnimatedProgressRing(
                    progress: module.progressPercent,
                    lineWidth: 5,
                    size: 48,
                    tintColor: module.progressPercent >= 1.0 ? .inkSuccess : .inkAccent
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(module.progressPercent >= 1.0 ? "Tamamlandı" : "İlerleme")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.inkTextPrimary)

                    Text("\(module.completedLessonsCount) / \(module.lessons.count) ders tamamlandı")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.inkTextTertiary)
                }

                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.inkDivider)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(module.progressPercent >= 1.0 ? Color.inkSuccess : Color.inkAccent)
                        .frame(
                            width: geo.size.width * CGFloat(min(module.progressPercent, 1.0)),
                            height: 4
                        )
                }
            }
            .frame(height: 4)
        }
        .padding(AppSpacing.lg)
        .premiumCard()
    }

    // MARK: - 3. Lessons

    private var lessonsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Dersler")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkTextPrimary)

                Spacer()

                Text("\(module.lessons.count) ders")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkTextTertiary)
            }
            .padding(.bottom, 8)

            let sorted = module.lessons.sorted { $0.order < $1.order }
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, lesson in
                if index > 0 {
                    Divider()
                        .padding(.leading, 50)
                }

                if module.isLocked {
                    LessonRowView(lesson: lesson, index: index + 1, isLocked: true)
                } else {
                    NavigationLink(value: lesson) {
                        LessonRowView(lesson: lesson, index: index + 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppSpacing.lg)
        .premiumCard()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ModuleDetailView(
            module: TrainingModule(
                id: "1",
                title: "Dövme Sanatına Giriş",
                description: "Bu modülde dövme sanatının temel prensiplerini, tarihçesini ve güvenlik kurallarını öğreneceksin.",
                imageURL: nil,
                lessons: [
                    Lesson(id: "1", title: "Dövme Tarihçesi", videoURL: URL(string: "https://example.com"), duration: 720, order: 1, isCompleted: true, description: ""),
                    Lesson(id: "2", title: "Hijyen ve Güvenlik", videoURL: URL(string: "https://example.com"), duration: 540, order: 2, isCompleted: true, description: ""),
                    Lesson(id: "3", title: "Ekipman Tanıtımı", videoURL: nil, duration: 840, order: 3, isCompleted: false, description: ""),
                    Lesson(id: "4", title: "İlk Çalışma", videoURL: nil, duration: 660, order: 4, isCompleted: false, description: "")
                ],
                isLocked: false
            ),
            moduleService: MockModuleService(),
            assignmentService: MockAssignmentService()
        )
    }
}