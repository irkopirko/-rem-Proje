import SwiftUI

struct AssignmentsListView: View {
    let container: DIContainer
    @State private var catalog = CatalogService()
    @State private var items: [HomeworkAssignmentDTO] = []

    private var incomplete: [HomeworkAssignmentDTO] {
        items.filter { $0.status == "pending" || $0.status == "graded_revise" }
    }

    private var awaitingReview: [HomeworkAssignmentDTO] {
        items.filter { $0.status == "submitted" || $0.status == "grading" }
    }

    private var completed: [HomeworkAssignmentDTO] {
        items.filter { $0.status == "graded_pass" }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    InkMockSectionTitle(text: "Ödevler")

                    sectionHeader("Tamamlanmamış Ödevler")
                    homeworkSection(incomplete)

                    sectionHeader("Değerlendirilmeyi Bekleyen Ödevler")
                    homeworkSection(awaitingReview, showStatus: true)

                    sectionHeader("Tamamlanmış Ödevler")
                    homeworkSection(completed, showStatus: true)
                }
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .studentScreenBackground()
            .navigationBarHidden(true)
            .task { items = (try? await catalog.fetchHomework()) ?? [] }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.inkTextPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func homeworkSection(_ list: [HomeworkAssignmentDTO], showStatus: Bool = false) -> some View {
        if list.isEmpty {
            InkMockSubheading(text: "—")
        } else {
            VStack(spacing: 10) {
                ForEach(list) { item in
                    NavigationLink {
                        HomeworkDetailView(item: item)
                    } label: {
                        InkMockHomeworkPill(
                            title: item.title,
                            subtitle: showStatus ? statusLabel(item) : nil
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func statusLabel(_ item: HomeworkAssignmentDTO) -> String {
        switch item.status {
        case "submitted", "grading": return "Değerlendirme aşamasında."
        case "graded_pass": return "Değerlendirildi."
        case "graded_revise": return "Revize isteniyor."
        default: return ""
        }
    }
}

struct HomeworkDetailView: View {
    let item: HomeworkAssignmentDTO

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(item.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(InkMockup.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let due = HomeworkDateFormat.display(item.dueAt) {
                    Label("Son teslim: \(due)", systemImage: "calendar")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(InkMockup.captionColor)
                }

                if !item.gallery.isEmpty {
                    ProductGalleryView(images: item.gallery, height: 260)
                }

                Text(item.explanation)
                    .font(.system(size: 15))
                    .foregroundStyle(InkMockup.captionColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                if item.status == "submitted" || item.status == "grading" {
                    Text("Ödeviniz gönderildi. Değerlendiriyoruz.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.inkWarning)
                }

                if let score = item.latestScore {
                    Text("Not: \(score)")
                        .font(.headline)
                }

                if item.status == "pending" || item.status == "graded_revise" {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                        .foregroundStyle(InkMockup.captionColor.opacity(0.5))
                        .frame(height: 140)
                        .overlay(
                            Text("dosya yükleme kısmı")
                                .font(.system(size: 13))
                                .foregroundStyle(InkMockup.captionColor)
                        )

                    InkMockPrimaryButton(title: "Yükle") {}
                }
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.vertical, 20)
        }
        .studentScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}
