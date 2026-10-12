import SwiftUI

struct CrewRootView: View {
    let container: DIContainer
    @State private var selected = 0
    @State private var showCommunity = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            tabs
        }
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $showCommunity) {
            NavigationStack {
                CommunityFeedView(container: container)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Kapat") { showCommunity = false }
                        }
                    }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { showCommunity = true } label: {
                Image("HomeChatIcon")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .accessibilityLabel("Topluluk")

            VStack(alignment: .leading, spacing: 2) {
                Text("INK AKADEMI CREW")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(InkMockup.textPrimary)
                Text("Eğitmen / içerik paneli")
                    .font(.system(size: 12))
                    .foregroundStyle(InkMockup.captionColor)
            }
            Spacer(minLength: 8)
            Button {
                Task { await container.completeLogout() }
            } label: {
                Label("Çıkış", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(InkMockup.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(InkMockup.fieldFill, in: Capsule())
            }
            .accessibilityLabel("Crew panelinden çıkış yap")
        }
        .padding(.horizontal, InkMockup.screenHorizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private var tabs: some View {
        TabView(selection: $selected) {
            CrewStudentsView()
                .tabItem { Label("Öğrenciler", systemImage: "person.3.fill") }
                .tag(0)
            CrewLearningView()
                .tabItem { Label("Eğitim", systemImage: "video.fill") }
                .tag(1)
            CrewHomeworkView()
                .tabItem { Label("Ödevler", systemImage: "doc.text.fill") }
                .tag(2)
            CrewProductsView()
                .tabItem { Label("Ürünler", systemImage: "bag.fill") }
                .tag(3)
        }
        .tint(Color.inkAccent)
    }
}

struct CrewStudentsView: View {
    @State private var students: [CrewStudentDTO] = []

    var body: some View {
        NavigationStack {
            List(students) { s in
                NavigationLink("\(s.firstName) \(s.lastName)") {
                    CrewStudentDetailView(studentId: s.id)
                }
            }
            .navigationTitle("Öğrenciler")
            .task { await load() }
        }
    }

    private func load() async {
        struct Resp: Decodable { let students: [CrewStudentDTO] }
        if let resp: Resp = try? await InkAPIClient.shared.request("/v1/crew/students", authorized: true) {
            students = resp.students
        }
    }
}

struct CrewStudentDTO: Identifiable, Decodable {
    let id: String
    let userNo: Int
    var username: String? = nil
    let firstName: String
    let lastName: String
    let membershipStatus: String
    var chatBanned: Bool? = nil
}

struct CrewStudentDetailView: View {
    let studentId: String
    @State private var detail: CrewStudentDetailResponse?

    var body: some View {
        List {
            if let detail {
                Section("İlerleme") {
                    ForEach(detail.videoProgress, id: \.title) { v in
                        HStack {
                            Text(v.title)
                            Spacer()
                            if v.completed { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.inkSage) }
                        }
                    }
                }
                Section("Rozetler") {
                    ForEach(detail.badges, id: \.title) { b in
                        Text(b.title)
                    }
                }
            }
        }
        .navigationTitle("Öğrenci detay")
        .task { await load() }
    }

    private func load() async {
        detail = try? await InkAPIClient.shared.request("/v1/crew/students/\(studentId)", authorized: true)
    }
}

struct CrewStudentDetailResponse: Decodable {
    struct Progress: Decodable {
        let title: String
        let completed: Bool
    }
    struct Badge: Decodable { let title: String }
    let videoProgress: [Progress]
    let badges: [Badge]
}

struct CrewHomeworkItem: Identifiable, Decodable {
    let assignmentId: String
    let title: String
    let firstName: String
    let lastName: String
    let status: String
    var fileUrl: String? = nil
    var files: [HomeworkFileDTO]? = nil
    var id: String { assignmentId }
    var submittedFiles: [HomeworkFileDTO] { files ?? [] }
}
