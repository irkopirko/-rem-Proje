import SwiftUI

struct PracticeView: View {
    let ecosystem: EcosystemCatalogServing

    @State private var tasks: [PracticeTask] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                Text("Stencil, çizim ve fake skin görevleri — yükleme alanı şimdilik mock.")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkTextSecondary)

                ForEach(PracticeTaskType.allCases, id: \.self) { type in
                    let subset = tasks.filter { $0.type == type }
                    if !subset.isEmpty {
                        SectionHeaderView(text: type.rawValue.capitalized)
                        ForEach(subset) { task in
                            taskCard(task)
                        }
                    }
                }

                mockUploadSection
            }
            .padding(AppSpacing.screenH)
            .padding(.vertical, AppSpacing.lg)
        }
        .inkPageBackground()
        .navigationTitle("Pratik Alanı")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .overlay {
            if isLoading { ProgressView() }
        }
    }

    private func taskCard(_ task: PracticeTask) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(task.title)
                    .font(.headline)
                Spacer()
                statusChip(task.status)
            }
            Text(task.description)
                .font(.subheadline)
                .foregroundStyle(Color.inkTextSecondary)
            Text("Yükleme: \(task.requiredUploadType) · +\(task.xpReward) XP")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.inkTeal)
        }
        .padding(AppSpacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func statusChip(_ status: PracticeTaskStatus) -> some View {
        Text(statusLabel(status))
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusLabel(_ s: PracticeTaskStatus) -> String {
        switch s {
        case .pending: return "Bekliyor"
        case .submitted: return "Gönderildi"
        case .reviewed: return "Değerlendirildi"
        }
    }

    private func statusColor(_ s: PracticeTaskStatus) -> Color {
        switch s {
        case .pending: return .inkWarning
        case .submitted: return .inkIndigo
        case .reviewed: return .inkSage
        }
    }

    private var mockUploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(text: "Mock yükleme")
            RoundedRectangle(cornerRadius: 16)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(Color.inkBorder)
                .frame(height: 140)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                        Text("Fotoğraf / video buraya sürüklenecek (Supabase storage)")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.inkTextTertiary)
                    }
                    .padding()
                }
        }
    }

    private func load() async {
        isLoading = true
        tasks = await ecosystem.fetchPracticeTasks()
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        PracticeView(ecosystem: MockEcosystemCatalogService())
    }
}
