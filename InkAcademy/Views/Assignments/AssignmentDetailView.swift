import SwiftUI

struct AssignmentDetailView: View {
    let assignment: Assignment
    @Bindable var viewModel: AssignmentsViewModel
    @State private var showUpload = false
    @State private var assignmentState: Assignment

    init(assignment: Assignment, viewModel: AssignmentsViewModel) {
        self.assignment = assignment
        self.viewModel = viewModel
        self._assignmentState = State(initialValue: assignment)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // 1 — Header
                headerSection

                // 2 — Description
                descriptionCard

                // 3 — Submission info
                if let subDate = assignmentState.submissionDate {
                    submissionInfoCard(date: subDate)
                }

                // 4 — Submitted file
                if assignmentState.fileURL != nil {
                    submittedFileCard
                }

                // 5 — Upload action (pending or revision requested)
                if assignmentState.status == .pending || assignmentState.status == .revisionRequested {
                    uploadAction
                }

                // 6 — Instructor feedback (navigates to detail)
                if let feedback = assignmentState.feedback {
                    NavigationLink(value: feedback) {
                        feedbackPreviewCard(feedback)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.screenH)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(Color.inkBackground)
        .navigationTitle("Ödev Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Feedback.self) { feedback in
            FeedbackDetailView(viewModel: FeedbackDetailViewModel(
                assignment: assignment,
                feedback: feedback,
                assignmentService: viewModel.assignmentService
            ))
        }
        .sheet(isPresented: $showUpload) {
            AssignmentUploadView(viewModel: AssignmentUploadViewModel(
                assignment: assignment,
                assignmentService: viewModel.assignmentService
            ))
        }
        .onChange(of: showUpload) { _, isPresented in
            if !isPresented {
                Task { await viewModel.loadAssignments() }
            }
        }
        .onChange(of: viewModel.assignments) { _, assignments in
            if let updated = assignments.first(where: { $0.id == assignmentState.id }) {
                assignmentState = updated
            }
        }
    }

    // MARK: - 1. Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                StatusBadgeView(status: assignmentState.status)
                Spacer()
                dueDateLabel
            }

            Text(assignmentState.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.inkTextPrimary)

            HStack(spacing: 12) {
                summaryPill(icon: "doc.text.fill", text: "Ödev")
                if assignmentState.fileURL != nil {
                    summaryPill(icon: "checkmark.circle.fill", text: "Teslim var")
                }
            }
        }
        .padding(18)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.inkGold.opacity(0.14), lineWidth: 0.8)
        )
    }

    private var dueDateLabel: some View {
        let overdue = assignmentState.dueDate.isOverdue && assignmentState.status == .pending
        return Label(assignmentState.dueDate.formatted_ddMMyyyy, systemImage: "calendar")
            .font(.caption)
            .foregroundStyle(overdue ? Color.inkError : Color.inkTextTertiary)
    }

    // MARK: - 2. Description

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(text: "Açıklama")

            Text(assignmentState.description)
                .font(.subheadline)
                .foregroundStyle(Color.inkTextSecondary)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.inkDivider, lineWidth: 0.5)
        )
    }

    // MARK: - 3. Submission info

    private func submissionInfoCard(date: Date) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.inkSurfaceSecondary)
                    .frame(width: 40, height: 40)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.inkTextSecondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Gönderim Tarihi")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.inkTextTertiary)

                Text(date.formatted_ddMMyyyy)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.inkTextPrimary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.inkDivider, lineWidth: 0.5)
        )
    }

    // MARK: - 4. Submitted file

    private var submittedFileCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.inkSuccess.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: "doc.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.inkSuccess)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Dosya Yüklendi")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.inkTextPrimary)

                Text("Başarıyla gönderildi")
                    .font(.caption)
                    .foregroundStyle(Color.inkTextTertiary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.inkSuccess)
        }
        .padding(16)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.inkDivider, lineWidth: 0.5)
        )
    }

    // MARK: - 5. Upload action

    private var uploadAction: some View {
        Button {
            showUpload = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: assignmentState.status == .revisionRequested
                      ? "arrow.triangle.2.circlepath"
                      : "arrow.up.circle.fill")
                    .font(.system(size: 15, weight: .medium))
                Text(assignmentState.status == .revisionRequested
                     ? "Yeniden Yükle"
                     : "Ödev Yükle")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(assignmentState.status == .revisionRequested ? Color.inkError : Color.inkAccent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous))
        }
    }

    // MARK: - 6. Feedback preview

    private func feedbackPreviewCard(_ feedback: Feedback) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeaderView(text: "Eğitmen Değerlendirmesi")

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.inkSurfaceSecondary)
                        .frame(width: 36, height: 36)

                    Text(initials(from: feedback.instructorName))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.inkTextSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(feedback.instructorName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.inkTextPrimary)

                    Text(feedback.comment)
                        .font(.caption)
                        .foregroundStyle(Color.inkTextTertiary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.inkTextTertiary)
                    Text("\(feedback.rating)/10")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.inkTextPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.inkSurfaceSecondary)
                .clipShape(Capsule())

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

    // MARK: - Helpers

    private func initials(from name: String) -> String {
        let parts = name.replacingOccurrences(of: "Eğitmen ", with: "").split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    private func summaryPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(Color.inkGold)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.inkGoldSoft)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AssignmentDetailView(
            assignment: Assignment(
                id: "1",
                title: "İlk Dövme Tasarımı",
                description: "Basit bir çiçek veya geometrik şekil tasarımı çizin ve fotoğrafını yükleyin.",
                dueDate: .now.addingTimeInterval(86400 * 5),
                submissionDate: .now.addingTimeInterval(-86400),
                fileURL: URL(string: "https://example.com/upload.jpg"),
                status: .revisionRequested,
                feedback: Feedback(
                    id: "f1",
                    assignmentId: "1",
                    instructorId: "i1",
                    instructorName: "Eğitmen Elif Kaya",
                    comment: "Tasarımda oranları gözden geçir.",
                    rating: 5,
                    date: .now.addingTimeInterval(-3600)
                )
            ),
            viewModel: AssignmentsViewModel(assignmentService: MockAssignmentService())
        )
    }
}
