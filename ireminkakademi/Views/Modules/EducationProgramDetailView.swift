import SwiftUI

struct EducationProgramDetailView: View {
    let program: EducationProgramDTO
    let container: DIContainer
    @State private var catalog = CatalogService()
    @State private var detail: ProgramDetailResponse?
    @State private var loadError: String?

    private var shown: EducationProgramDTO { detail?.program ?? program }
    private var modules: [ModuleDTO] { detail?.modules ?? [] }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    Text(shown.numberLabel)
                        .font(AppTypography.monoMedium(size: 13))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(InkGlass.burgundy.opacity(0.7)))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shown.title)
                            .font(AppTypography.sectionHeading())
                            .tracking(AppTypography.tracking(forDisplaySize: 26))
                            .foregroundStyle(InkMockup.textPrimary)
                        if let instructor = shown.instructorName, !instructor.isEmpty {
                            Text(instructor)
                                .font(AppTypography.monoMedium(size: 12))
                                .foregroundStyle(InkMockup.accentPink)
                        }
                    }
                }

                if let desc = shown.description, !desc.isEmpty {
                    Text(desc)
                        .font(AppTypography.body())
                        .foregroundStyle(InkMockup.textPrimary.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 4)
                }

                InkMockSubheading(text: "Modüller")

                if detail != nil {
                    if modules.isEmpty {
                        Text("Bu eğitimde henüz yayınlanmış modül yok.")
                            .font(AppTypography.body())
                            .foregroundStyle(InkMockup.captionColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    }
                    ForEach(modules) { module in
                        NavigationLink(value: module) {
                            ModuleCard(module: module)
                        }
                        .buttonStyle(.plain)
                    }
                } else if let loadError {
                    Text(loadError)
                        .font(.system(size: 15))
                        .foregroundStyle(InkMockup.captionColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                } else {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 32)
                }
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.vertical, 16)
        }
        .studentScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
    }

    private func load() async {
        do {
            detail = try await catalog.fetchProgram(id: program.id)
        } catch {
            if detail == nil { loadError = error.localizedDescription }
        }
    }
}
