import SwiftUI

struct AssignmentsListView: View {
    @Bindable var viewModel: AssignmentsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                    summaryCard

                    if let errorMessage = viewModel.errorMessage {
                        ErrorBannerView(message: errorMessage)
                    }

                    if !viewModel.revisionRequestedAssignments.isEmpty {
                        assignmentSection(title: "Revizyon İstenen", assignments: viewModel.revisionRequestedAssignments)
                    }

                    if !viewModel.pendingAssignments.isEmpty {
                        assignmentSection(title: "Bekleyen", assignments: viewModel.pendingAssignments)
                    }

                    if !viewModel.submittedAssignments.isEmpty {
                        assignmentSection(title: "Gönderilen", assignments: viewModel.submittedAssignments)
                    }

                    if !viewModel.reviewedAssignments.isEmpty {
                        assignmentSection(title: "Değerlendirilen", assignments: viewModel.reviewedAssignments)
                    }
                }
                .padding(.horizontal, AppSpacing.screenH)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(Color.inkBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Assignment.self) { assignment in
                AssignmentDetailView(assignment: assignment, viewModel: viewModel)
            }
            .task {
                await viewModel.loadAssignments()
            }
            .refreshable {
                await viewModel.loadAssignments()
            }
            .loadingOverlay(isLoading: viewModel.isLoading)
            .overlay {
                if viewModel.assignments.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "Henüz ödev yok",
                        systemImage: "doc.text",
                        description: Text("Ödevler burada görünecek.")
                    )
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        AnimatedDashboardCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ödev Takibi")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.inkTextPrimary)

                        Text(summarySubtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.inkTextSecondary)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.inkIndigoSoft)
                            .frame(width: 50, height: 50)

                        Image(systemName: "doc.badge.clock.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.inkIndigo)
                    }
                }

                HStack(spacing: 12) {
                    DashboardStatCard(
                        title: "Bekleyen",
                        value: "\(viewModel.pendingAssignments.count)",
                        icon: "clock.fill",
                        subtitle: "teslim",
                        accentColor: .inkIndigo
                    )

                    DashboardStatCard(
                        title: "İncelenen",
                        value: "\(viewModel.reviewedAssignments.count)",
                        icon: "checkmark.seal.fill",
                        subtitle: "tamam",
                        accentColor: .inkSage
                    )
                }
            }
        }
    }

    // MARK: - Assignment Section

    private func assignmentSection(title: String, assignments: [Assignment]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeaderView(text: title)

            VStack(spacing: 0) {
                ForEach(Array(assignments.enumerated()), id: \.element.id) { index, assignment in
                    NavigationLink(value: assignment) {
                        assignmentRow(assignment)
                    }
                    .buttonStyle(.plain)

                    if index < assignments.count - 1 {
                        Divider()
                            .padding(.leading, 58)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(Color.inkSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous)
                    .stroke(sectionAccent(for: title).opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: AppShadows.softRadius, x: 0, y: AppShadows.softY)
        }
    }

    private func assignmentRow(_ assignment: Assignment) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadii.sm, style: .continuous)
                    .fill(iconBackground(for: assignment.status))
                    .frame(width: 40, height: 40)

                Image(systemName: iconName(for: assignment.status))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor(for: assignment.status))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.inkTextPrimary)
                    .lineLimit(1)

                let overdue = assignment.dueDate.isOverdue && assignment.status == .pending
                Label(assignment.dueDate.formatted_ddMMyyyy, systemImage: "calendar")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(overdue ? Color.inkError : Color.inkTextTertiary)
            }

            Spacer()

            StatusBadgeView(status: assignment.status)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.inkTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private var summarySubtitle: String {
        if let nextDue = viewModel.nextDueAssignment {
            return "\(nextDue.title) sıradaki teslim"
        }
        return "Gönderimlerin ve değerlendirmelerin burada"
    }

    private func sectionAccent(for title: String) -> Color {
        switch title {
        case "Revizyon İstenen": return .inkRose
        case "Bekleyen": return .inkIndigo
        case "Gönderilen": return .inkTeal
        case "Değerlendirilen": return .inkSage
        default: return .inkDivider
        }
    }

    private func iconName(for status: Assignment.Status) -> String {
        switch status {
        case .pending: return "doc.text"
        case .submitted: return "arrow.up.doc"
        case .reviewed: return "checkmark.seal"
        case .revisionRequested: return "exclamationmark.arrow.triangle.2.circlepath"
        }
    }

    private func iconColor(for status: Assignment.Status) -> Color {
        switch status {
        case .pending: return .inkIndigo
        case .submitted: return .inkTeal
        case .reviewed: return .inkSage
        case .revisionRequested: return .inkRose
        }
    }

    private func iconBackground(for status: Assignment.Status) -> Color {
        switch status {
        case .pending: return Color.inkIndigoSoft
        case .submitted: return Color.inkTealSoft
        case .reviewed: return Color.inkSageSoft
        case .revisionRequested: return Color.inkRoseSoft
        }
    }
}

#Preview {
    AssignmentsListView(viewModel: AssignmentsViewModel(
        assignmentService: MockAssignmentService()
    ))
}