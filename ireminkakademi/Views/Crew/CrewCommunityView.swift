import SwiftUI

struct CrewCommunityView: View {
    let container: DIContainer

    private enum Tab: String, CaseIterable, Identifiable {
        case room = "Sohbet"
        case reports = "Bildirimler"
        case banned = "Yasaklılar"
        var id: String { rawValue }
    }

    @State private var tab: Tab = .room

    var body: some View {
        VStack(spacing: 0) {
            Picker("Görünüm", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            switch tab {
            case .room: CommunityRoomView(container: container)
            case .reports: CrewReportsList()
            case .banned: CrewBannedList()
            }
        }
        .navigationTitle("Sohbet")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CrewReportsList: View {
    private let service = CommunityModerationService()
    @State private var reports: [CommunityReport] = []
    @State private var didLoad = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if reports.isEmpty, didLoad {
                ContentUnavailableView("Bekleyen bildirim yok", systemImage: "checkmark.shield")
            }
            ForEach(reports) { report in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(report.authorUsername.map { "@\($0)" } ?? report.authorFirstName)
                            .font(.system(size: 14, weight: .bold))
                        if report.authorBanned {
                            Text("Yasaklı").font(.system(size: 10, weight: .bold)).foregroundStyle(.red)
                        }
                        Spacer()
                        Text("\(report.reportCount) bildirim").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    Text(report.body)
                        .font(.system(size: 15))
                        .strikethrough(report.messageDeleted)
                        .foregroundStyle(report.messageDeleted ? .secondary : .primary)
                    Text("Sebep: \(report.reason ?? "Belirtilmedi") · Bildiren: \(report.reporterUsername.map { "@\($0)" } ?? "—")")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        if !report.messageDeleted {
                            Button("Mesajı sil", role: .destructive) {
                                act { try await service.deleteMessage(id: report.messageId) }
                            }
                        }
                        Button(report.authorBanned ? "Yasağı kaldır" : "Sohbetten yasakla") {
                            act { try await service.setBan(userId: report.authorId, banned: !report.authorBanned) }
                        }
                        Spacer()
                        Button("Çözüldü") {
                            act { try await service.resolve(reportId: report.id) }
                        }
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(.bordered)
                    .font(.system(size: 12))
                }
                .padding(.vertical, 4)
            }
        }
        .refreshable { await load() }
        .task {
            await load()
            didLoad = true
        }
        .alert("Hata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func act(_ operation: @escaping () async throws -> Void) {
        Task {
            do { try await operation() } catch { errorMessage = AuthErrorMessage.from(error) }
            await load()
        }
    }

    private func load() async {
        do {
            reports = try await service.fetchReports()
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}

private struct CrewBannedList: View {
    private let service = CommunityModerationService()
    @State private var students: [CrewStudentDTO] = []
    @State private var didLoad = false
    @State private var errorMessage: String?

    private var banned: [CrewStudentDTO] { students.filter { $0.chatBanned == true } }

    var body: some View {
        List {
            if banned.isEmpty, didLoad {
                ContentUnavailableView(
                    "Yasaklı kullanıcı yok",
                    systemImage: "person.crop.circle.badge.checkmark",
                    description: Text("Bildirimler sekmesinden veya sohbette bir mesaja basılı tutarak kullanıcıları yönetebilirsin.")
                )
            }
            ForEach(banned) { student in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(student.firstName) \(student.lastName)").font(.system(size: 15, weight: .semibold))
                        if let username = student.username {
                            Text("@\(username)").font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("Yasağı kaldır") {
                        Task {
                            do { try await service.setBan(userId: student.id, banned: false) } catch { errorMessage = AuthErrorMessage.from(error) }
                            await load()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .refreshable { await load() }
        .task {
            await load()
            didLoad = true
        }
        .alert("Hata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func load() async {
        struct Resp: Decodable { let students: [CrewStudentDTO] }
        do {
            let resp: Resp = try await InkAPIClient.shared.request("/v1/crew/students", authorized: true)
            students = resp.students
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}
