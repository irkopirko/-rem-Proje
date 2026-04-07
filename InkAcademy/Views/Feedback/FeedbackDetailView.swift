import SwiftUI

struct FeedbackDetailView: View {
    let viewModel: FeedbackDetailViewModel
    @State private var showUpload = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // 1 — Assignment header
                assignmentHeader

                // 2 — Submission image preview
                if viewModel.hasSubmittedFile {
                    imagePreviewCard
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // 3 — Score + status
                scoreSection

                // 4 — Instructor comment
                commentCard

                // 5 — Timeline
                timelineCard

                // 6 — Re-upload (revision requested)
                if viewModel.isRevisionRequested {
                    reUploadButton
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isRevisionRequested)
        }
        .background(Color.inkBackground)
        .navigationTitle("Değerlendirme")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showUpload) {
            AssignmentUploadView(viewModel: AssignmentUploadViewModel(
                assignment: viewModel.assignment,
                assignmentService: viewModel.assignmentService
            ))
        }
    }

    // MARK: - 1. Assignment Header

    private var assignmentHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusBadgeView(status: viewModel.assignment.status)
                Spacer()
            }

            Text(viewModel.assignmentTitle)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.inkTextPrimary)

            Text(viewModel.assignment.description)
                .font(.subheadline)
                .foregroundStyle(Color.inkTextTertiary)
                .lineLimit(2)
        }
        .padding(18)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.inkGold.opacity(0.14), lineWidth: 0.8)
        )
    }

    // MARK: - 2. Image Preview

    private var imagePreviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(text: "Gönderilen Çalışma")

            // Placeholder image card — in production would load from fileURL
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.inkSurfaceSecondary)
                    .frame(height: 180)

                VStack(spacing: 8) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.inkTextTertiary)

                    Text("Yüklenen fotoğraf")
                        .font(.caption)
                        .foregroundStyle(Color.inkTextTertiary)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.inkDivider, lineWidth: 0.5)
            )
        }
    }

    // MARK: - 3. Score + Status

    private var scoreSection: some View {
        HStack(spacing: 20) {
            FeedbackScoreRing(
                score: viewModel.rating,
                maxScore: viewModel.ratingMax,
                size: 80
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(scoreSummary)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.inkTextPrimary)

                Text(viewModel.statusLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(statusColor)

                Text("Eğitmen: \(viewModel.instructorName)")
                    .font(.caption)
                    .foregroundStyle(Color.inkTextTertiary)
            }

            Spacer()
        }
        .padding(18)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(statusColor.opacity(0.14), lineWidth: 0.8)
        )
    }

    private var scoreSummary: String {
        let pct = viewModel.ratingProgress
        if pct >= 0.8 { return "Harika İş!" }
        if pct >= 0.5 { return "İyi Çalışma" }
        return "Geliştirmeye Açık"
    }

    private var statusColor: Color {
        if viewModel.isApproved { return .inkSuccess }
        if viewModel.isRevisionRequested { return .inkError }
        return .inkTextSecondary
    }

    // MARK: - 4. Instructor Comment

    private var commentCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeaderView(text: "Eğitmen Yorumu")

            VStack(alignment: .leading, spacing: 12) {
                // Instructor header
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.inkSurfaceSecondary)
                            .frame(width: 36, height: 36)

                        Text(viewModel.instructorInitials)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.inkTextSecondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.instructorName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.inkTextPrimary)

                        Text(viewModel.feedbackDateFormatted)
                            .font(.caption2)
                            .foregroundStyle(Color.inkTextTertiary)
                    }

                    Spacer()
                }

                // Comment body
                Text(viewModel.comment)
                    .font(.subheadline)
                    .foregroundStyle(Color.inkTextSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
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

    // MARK: - 5. Timeline

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeaderView(text: "Zaman Çizelgesi")

            VStack(spacing: 0) {
                if let subDate = viewModel.submissionDateFormatted {
                    timelineRow(
                        icon: "arrow.up.circle.fill",
                        label: "Gönderildi",
                        date: subDate,
                        color: .inkBlack,
                        isLast: false
                    )
                }

                timelineRow(
                    icon: "message.circle.fill",
                    label: "Değerlendirildi",
                    date: viewModel.feedbackDateFormatted,
                    color: viewModel.isRevisionRequested ? .inkError : .inkSuccess,
                    isLast: !viewModel.isRevisionRequested
                )

                if viewModel.isRevisionRequested {
                    timelineRow(
                        icon: "exclamationmark.circle.fill",
                        label: "Revizyon bekleniyor",
                        date: "—",
                        color: .inkError,
                        isLast: true
                    )
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

    private func timelineRow(icon: String, label: String, date: String, color: Color, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                    .frame(width: 20)

                if !isLast {
                    Rectangle()
                        .fill(Color.inkDivider)
                        .frame(width: 1.5, height: 24)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.inkTextPrimary)

                Text(date)
                    .font(.caption2)
                    .foregroundStyle(Color.inkTextTertiary)
            }
            .padding(.bottom, isLast ? 0 : 14)

            Spacer()
        }
    }

    // MARK: - 6. Re-upload

    private var reUploadButton: some View {
        VStack(spacing: 12) {
            // Warning banner
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkError)

                Text("Eğitmeniniz bu ödevde revizyon istedi. Lütfen düzeltip tekrar gönderin.")
                    .font(.caption)
                    .foregroundStyle(Color.inkTextSecondary)
                    .lineSpacing(3)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.inkError.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.inkError.opacity(0.15), lineWidth: 0.5)
            )

            // Button
            Button {
                showUpload = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Yeniden Yükle")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.inkError)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

}

// MARK: - Preview

#Preview("Revision Requested") {
    NavigationStack {
        FeedbackDetailView(viewModel: FeedbackDetailViewModel(
            assignment: Assignment(
                id: "1",
                title: "İlk Dövme Tasarımı",
                description: "Basit bir çiçek veya geometrik şekil tasarımı çizin.",
                dueDate: .now.addingTimeInterval(86400 * 5),
                submissionDate: .now.addingTimeInterval(-86400 * 3),
                fileURL: URL(string: "https://example.com/upload.jpg"),
                status: .revisionRequested,
                feedback: Feedback(
                    id: "f1", assignmentId: "1", instructorId: "i1",
                    instructorName: "Eğitmen Elif Kaya",
                    comment: "Tasarım güzel ama çiçek yapraklarının oranları tutarsız. Simetriyi gözden geçirip yeniden gönder.",
                    rating: 5,
                    date: .now.addingTimeInterval(-86400)
                )
            ),
            feedback: Feedback(
                id: "f1", assignmentId: "1", instructorId: "i1",
                instructorName: "Eğitmen Elif Kaya",
                comment: "Tasarım güzel ama çiçek yapraklarının oranları tutarsız. Simetriyi gözden geçirip yeniden gönder.",
                rating: 5,
                date: .now.addingTimeInterval(-86400)
            ),
            assignmentService: MockAssignmentService()
        ))
    }
}

#Preview("Approved") {
    NavigationStack {
        FeedbackDetailView(viewModel: FeedbackDetailViewModel(
            assignment: Assignment(
                id: "3",
                title: "Hijyen Protokolü Raporu",
                description: "Bir dövme stüdyosunun hijyen protokollerini araştırıp kısa bir rapor hazırlayın.",
                dueDate: .now.addingTimeInterval(-86400 * 10),
                submissionDate: .now.addingTimeInterval(-86400 * 8),
                fileURL: URL(string: "https://example.com/upload.pdf"),
                status: .reviewed,
                feedback: Feedback(
                    id: "f2", assignmentId: "3", instructorId: "i1",
                    instructorName: "Eğitmen Elif Kaya",
                    comment: "Çok detaylı ve kapsamlı bir rapor. Sterilizasyon bölümü özellikle başarılı.",
                    rating: 9,
                    date: .now.addingTimeInterval(-86400 * 6)
                )
            ),
            feedback: Feedback(
                id: "f2", assignmentId: "3", instructorId: "i1",
                instructorName: "Eğitmen Elif Kaya",
                comment: "Çok detaylı ve kapsamlı bir rapor. Sterilizasyon bölümü özellikle başarılı.",
                rating: 9,
                date: .now.addingTimeInterval(-86400 * 6)
            ),
            assignmentService: MockAssignmentService()
        ))
    }
}
