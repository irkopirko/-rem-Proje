import SwiftUI

struct EducationProgramDetailView: View {
    let program: EducationProgramDTO
    let container: DIContainer
    var hidesTabBar: Binding<Bool> = .constant(false)

    @Environment(\.dismiss) private var dismiss
    @State private var catalog = CatalogService()
    @State private var detail: ProgramDetailResponse?
    @State private var loadError: String?

    private var shown: EducationProgramDTO { detail?.program ?? program }
    private var modules: [ModuleDTO] { detail?.modules ?? [] }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        hero(width: geo.size.width, height: max(280, geo.size.height * 0.46))
                        detailBody
                            .padding(.horizontal, InkMockup.screenHorizontal)
                            .padding(.top, 22)
                            .padding(.bottom, 48)
                    }
                }
                .ignoresSafeArea(edges: .top)
                .safeAreaPadding(.bottom, 12)
            }
            backButton
        }
        .background(Color(hex: 0x0B080D).ignoresSafeArea())
        .studentScreenBackground()
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await load() }
        .task { await load() }
        .onAppear { hidesTabBar.wrappedValue = true }
    }

    private func hero(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            Group {
                if let url = shown.coverURL {
                    AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            heroFallback
                        }
                    }
                } else {
                    heroFallback
                }
            }
            .frame(width: width, height: height)
            .clipped()

            LinearGradient(
                colors: [
                    .clear,
                    Color(hex: 0x0B080D).opacity(0.15),
                    Color(hex: 0x481B30).opacity(0.55),
                    Color(hex: 0x0B080D),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: height)
        .clipped()
    }

    private var heroFallback: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x481B30), Color(hex: 0x211820), Color(hex: 0x0B080D)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 42))
                .foregroundStyle(.white.opacity(0.22))
        }
    }

    private var detailBody: some View {
        VStack(spacing: 18) {
            Text(shown.title)
                .font(AppTypography.sectionHeading(size: 28))
                .tracking(AppTypography.tracking(forDisplaySize: 28))
                .foregroundStyle(Color(hex: 0xF7F3F6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if !pills.isEmpty {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(pills.prefix(3), id: \.self) { MetaPill(text: $0) }
                    }
                    if pills.count > 3 {
                        HStack(spacing: 8) {
                            ForEach(pills.dropFirst(3), id: \.self) { MetaPill(text: $0) }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if let desc = shown.description, !desc.isEmpty {
                Text(desc)
                    .font(AppTypography.body())
                    .foregroundStyle(Color(hex: 0xADA1AA))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }

            if shown.videoCount > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("İlerleme")
                            .font(AppTypography.mono(size: 11))
                            .foregroundStyle(Color(hex: 0xADA1AA))
                        Spacer()
                        Text("\(shown.completedCount)/\(shown.videoCount) ders")
                            .font(AppTypography.mono(size: 11))
                            .foregroundStyle(Color(hex: 0xADA1AA))
                    }
                    GeometryReader { bar in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.10))
                            Capsule()
                                .fill(Color(hex: 0xC43B70))
                                .frame(width: max(6, bar.size.width * shown.progressFraction))
                        }
                    }
                    .frame(height: 3)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("MODÜLLER")
                    .font(AppTypography.monoMedium(size: 12))
                    .tracking(1.6)
                    .foregroundStyle(Color(hex: 0xADA1AA))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                if detail != nil {
                    if modules.isEmpty {
                        Text("Bu eğitimde henüz yayınlanmış modül yok.")
                            .font(AppTypography.body())
                            .foregroundStyle(Color(hex: 0xADA1AA))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                    }
                    ForEach(modules) { module in
                        NavigationLink(value: module) {
                            ModuleCard(module: module)
                        }
                        .buttonStyle(.plain)
                    }
                } else if let loadError {
                    Text(loadError)
                        .font(AppTypography.body())
                        .foregroundStyle(Color(hex: 0xADA1AA))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                } else {
                    ProgressView().tint(Color(hex: 0xC43B70)).frame(maxWidth: .infinity).padding(.top, 24)
                }
            }
        }
    }

    private var pills: [String] {
        var items: [String] = []
        if let instructor = shown.instructorName, !instructor.isEmpty { items.append(instructor) }
        if shown.moduleCount > 0 { items.append(shown.moduleCount == 1 ? "1 modül" : "\(shown.moduleCount) modül") }
        if shown.videoCount > 0 { items.append(shown.videoCount == 1 ? "1 ders" : "\(shown.videoCount) ders") }
        if let durationLabel = shown.durationLabel { items.append(durationLabel) }
        if let accessLabel = shown.accessLabel, !accessLabel.isEmpty { items.append(accessLabel) }
        return items
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.black.opacity(0.42), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 0.8))
        }
        .padding(.leading, 16)
        .padding(.top, 8)
        .buttonStyle(.plain)
        .accessibilityLabel("Geri")
    }

    private func load() async {
        do {
            detail = try await catalog.fetchProgram(id: program.id)
        } catch {
            if detail == nil { loadError = error.localizedDescription }
        }
    }
}

private struct MetaPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTypography.mono(size: 11))
            .foregroundStyle(Color(hex: 0xF7F3F6))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.08), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 0.6))
    }
}
