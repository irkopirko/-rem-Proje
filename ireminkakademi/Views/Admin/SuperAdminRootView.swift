import SwiftUI

struct SuperAdminRootView: View {
    let container: DIContainer
    @State private var users: [AdminUserRow] = []
    @State private var showCreateCrew = false

    var body: some View {
        NavigationStack {
            List {
                Section("Kontrol merkezi") {
                    Text("Tüm kayıtlar, crew hesapları ve audit log burada yönetilir. Sadece super admin erişebilir.")
                        .font(.caption)
                        .foregroundStyle(Color.inkTextSecondary)
                    Button("Yeni crew hesabı") { showCreateCrew = true }
                }

                Section("Kullanıcılar") {
                    ForEach(users) { u in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(u.firstName) \(u.lastName) · #\(u.userNo)")
                                .font(.subheadline.weight(.semibold))
                            Text("\(u.email) · \(u.role)")
                                .font(.caption)
                                .foregroundStyle(Color.inkTextSecondary)
                            HStack {
                                if u.role != "super_admin" {
                                    Button("Soft sil", role: .destructive) {
                                        Task { await softDelete(u.id) }
                                    }
                                    .font(.caption)
                                    Button("Kalıcı sil", role: .destructive) {
                                        Task { await purge(u.id) }
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Super Admin")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Çıkış") { Task { await container.completeLogout() } }
                }
            }
            .task { await load() }
            .refreshable { await load() }
            .sheet(isPresented: $showCreateCrew) {
                CreateCrewSheet(onCreated: { Task { await load() } })
            }
        }
    }

    private func load() async {
        struct Resp: Decodable { let users: [AdminUserRow] }
        if let resp: Resp = try? await InkAPIClient.shared.request("/v1/admin/users?includeDeleted=1", authorized: true) {
            users = resp.users
        }
    }

    private func softDelete(_ id: String) async {
        struct OK: Decodable { let ok: Bool }
        _ = try? await InkAPIClient.shared.request("/v1/admin/users/\(id)/soft-delete", method: "POST", authorized: true) as OK
        await load()
    }

    private func purge(_ id: String) async {
        struct OK: Decodable { let ok: Bool }
        var req = URLRequest(url: APIConfiguration.baseURL.appendingPathComponent("/v1/admin/users/\(id)/purge"))
        req.httpMethod = "DELETE"
        if let token = KeychainTokenStore.accessToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        _ = try? await URLSession.shared.data(for: req)
        await load()
    }
}

struct AdminUserRow: Identifiable, Decodable {
    let id: String
    let userNo: Int
    let email: String
    let firstName: String
    let lastName: String
    let role: String
    let deletedAt: String?
}

struct CreateCrewSheet: View {
    var onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("E-posta", text: $email).keyboardType(.emailAddress)
                SecureField("Geçici şifre", text: $password)
                TextField("İsim", text: $firstName)
                TextField("Soyisim", text: $lastName)
            }
            .navigationTitle("Crew oluştur")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        Task {
                            struct Body: Encodable {
                                let email: String
                                let password: String
                                let firstName: String
                                let lastName: String
                            }
                            struct Created: Decodable { let id: String }
                            _ = try? await InkAPIClient.shared.request(
                                "/v1/admin/crew",
                                method: "POST",
                                body: Body(email: email, password: password, firstName: firstName, lastName: lastName),
                                authorized: true
                            ) as Created
                            onCreated()
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
