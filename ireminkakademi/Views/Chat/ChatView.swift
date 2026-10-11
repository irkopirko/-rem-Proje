import SwiftUI

/// Öğrenci tarafı: tüm öğrenciler ve Ink Akademi Crew'un bulunduğu tek topluluk odası.
struct ChatView: View {
    let container: DIContainer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(InkMockup.textPrimary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Geri")
                Spacer()
                Text("Topluluk")
                    .font(AppTypography.cardTitle(size: 20))
                    .foregroundStyle(InkMockup.textPrimary)
                Spacer()
                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, InkMockup.screenHorizontal)
            .padding(.vertical, 8)

            CommunityRoomView(container: container) { dismiss() }
        }
        .studentScreenBackground()
        .navigationBarHidden(true)
    }
}

struct CommunityRoomView: View {
    let container: DIContainer
    var onDeclineRules: (() -> Void)? = nil
    @State private var client = CommunityChatClient()
    @State private var declinedRules = false
    @State private var draft = ""
    @State private var reporting: CommunityMessage?
    @State private var blocking: CommunityMessage?
    @AppStorage("communityRulesAccepted.v1") private var rulesAccepted = false
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var inputFocused: Bool

    private var myId: String? { container.sessionUser?.id }
    private var isStaff: Bool { container.sessionUser?.role == .crew || container.sessionUser?.role == .superAdmin }

    var body: some View {
        VStack(spacing: 0) {
            statusBar
            if client.state == .forbidden {
                ContentUnavailableView(
                    "Topluluk sohbeti kapalı",
                    systemImage: "lock.fill",
                    description: Text("Topluluğa katılmak için aktif üyelik gerekiyor.")
                )
            } else {
                messageList
                composer
            }
        }
        .onAppear {
            if isStaff { rulesAccepted = true }
            if rulesAccepted { client.connect() }
        }
        .onDisappear { client.disconnect() }
        .onChange(of: scenePhase) { _, phase in
            guard rulesAccepted else { return }
            if phase == .active { client.connect() } else if phase == .background { client.disconnect() }
        }
        .sheet(isPresented: Binding(get: { !rulesAccepted && !isStaff && !declinedRules }, set: { _ in })) {
            CommunityRulesSheet {
                rulesAccepted = true
                client.connect()
            } onDecline: {
                declinedRules = true
                onDeclineRules?()
            }
            .interactiveDismissDisabled()
        }
        .confirmationDialog("Mesajı neden bildiriyorsun?", isPresented: Binding(get: { reporting != nil }, set: { if !$0 { reporting = nil } }), titleVisibility: .visible) {
            ForEach(["Hakaret veya taciz", "Spam / reklam", "Uygunsuz içerik", "Diğer"], id: \.self) { reason in
                Button(reason) {
                    guard let message = reporting else { return }
                    Task { await client.report(message, reason: reason) }
                }
            }
        }
        .confirmationDialog(
            "\(blocking?.displayName ?? "") engellensin mi? Mesajlarını artık görmeyeceksin.",
            isPresented: Binding(get: { blocking != nil }, set: { if !$0 { blocking = nil } }),
            titleVisibility: .visible
        ) {
            Button("Engelle", role: .destructive) {
                guard let message = blocking else { return }
                Task { await client.block(userId: message.userId) }
            }
        }
        .alert("Topluluk", isPresented: Binding(get: { client.notice != nil }, set: { if !$0 { client.notice = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(client.notice ?? "")
        }
    }

    @ViewBuilder
    private var statusBar: some View {
        switch client.state {
        case .connecting:
            banner("Bağlanıyor…", systemImage: "antenna.radiowaves.left.and.right", color: .orange)
        case .offline:
            banner("Bağlantı yok, yeniden deneniyor…", systemImage: "wifi.slash", color: .orange)
        default:
            if !client.canSend {
                banner("Sohbete mesaj gönderme iznin kaldırıldı. Mesajları okuyabilirsin.", systemImage: "nosign", color: .red)
            }
        }
    }

    private func banner(_ text: String, systemImage: String, color: Color) -> some View {
        Label(text, systemImage: systemImage)
            .font(AppTypography.caption(size: 12))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if client.hasMore, !client.messages.isEmpty {
                        Button {
                            Task { await client.loadOlder() }
                        } label: {
                            if client.isLoadingOlder {
                                ProgressView()
                            } else {
                                Text("Daha eski mesajlar").font(AppTypography.button(size: 13))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(InkMockup.captionColor)
                        .padding(.vertical, 6)
                    }

                    if client.messages.isEmpty, client.pending.isEmpty, client.state == .online {
                        Text("Henüz mesaj yok. İlk mesajı sen yaz!")
                            .font(AppTypography.body(size: 14))
                            .foregroundStyle(InkMockup.captionColor)
                            .padding(.top, 40)
                    }

                    ForEach(timelineRows) { row in
                        switch row {
                        case .day(let date):
                            dayHeader(date)
                        case .message(let message):
                            bubble(message).id(message.id)
                        case .pending(let message):
                            pendingBubble(message).id(message.id)
                        }
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, InkMockup.screenHorizontal)
                .padding(.vertical, 10)
            }
            .scrollDismissesKeyboard(.interactively)
            .defaultScrollAnchor(.bottom)
            .onChange(of: client.messages.last?.id) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: client.pending.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    private var timelineRows: [ChatTimelineRow] {
        var rows: [ChatTimelineRow] = []
        var lastDay: Date?
        let calendar = ChatDay.calendar
        for message in client.messages {
            let day = calendar.startOfDay(for: message.date ?? .now)
            if lastDay != day {
                rows.append(.day(day))
                lastDay = day
            }
            rows.append(.message(message))
        }
        if !client.pending.isEmpty {
            let today = calendar.startOfDay(for: .now)
            if lastDay != today {
                rows.append(.day(today))
            }
            for message in client.pending {
                rows.append(.pending(message))
            }
        }
        return rows
    }

    private func dayHeader(_ date: Date) -> some View {
        Text(ChatDay.title(for: date))
            .font(AppTypography.monoMedium(size: 11))
            .foregroundStyle(InkMockup.captionColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(InkGlass.surface.opacity(0.72), in: Capsule())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }

    @ViewBuilder
    private func bubble(_ message: CommunityMessage) -> some View {
        let isMe = message.userId == myId
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 48) }
            if !isMe {
                ProfileAvatarView(url: message.photoURL, initials: message.isStaff ? "IA" : message.initials, size: 32, frame: message.avatarFrame, rank: message.rank)
                    .padding(.bottom, 16)
            }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                if !isMe {
                    HStack(spacing: 4) {
                        Text(message.displayName)
                            .font(AppTypography.profileLabel(size: 13))
                            .foregroundStyle(message.isStaff ? InkMockup.accentPink : InkMockup.captionColor)
                        if message.isStaff {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(InkMockup.accentPink)
                        }
                    }
                }
                Text(message.body)
                    .font(AppTypography.body())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isMe ? InkMockup.accentPink.opacity(0.88) : InkGlass.surface.opacity(0.72))
                    .foregroundStyle(isMe ? .white : InkMockup.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        if message.isStaff, !isMe {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(InkMockup.accentPink.opacity(0.5), lineWidth: 1)
                        }
                    }
                    .contextMenu { menu(for: message, isMe: isMe) }
                if let date = message.date {
                    Text(date, format: .dateTime.hour().minute())
                        .font(AppTypography.mono(size: 10))
                        .foregroundStyle(InkMockup.captionColor)
                }
            }
            if !isMe { Spacer(minLength: 48) }
        }
    }

    @ViewBuilder
    private func menu(for message: CommunityMessage, isMe: Bool) -> some View {
        Button {
            UIPasteboard.general.string = message.body
        } label: {
            Label("Kopyala", systemImage: "doc.on.doc")
        }
        if !isMe {
            Button { reporting = message } label: { Label("Bildir", systemImage: "exclamationmark.bubble") }
            if !message.isStaff, !isStaff {
                Button(role: .destructive) { blocking = message } label: { Label("Kullanıcıyı engelle", systemImage: "hand.raised") }
            }
        }
        if isMe || isStaff {
            Button(role: .destructive) {
                Task { await client.delete(message) }
            } label: {
                Label("Mesajı sil", systemImage: "trash")
            }
        }
        if isStaff, !message.isStaff {
            Button(role: .destructive) {
                Task {
                    do {
                        try await CommunityModerationService().setBan(userId: message.userId, banned: true)
                        client.notice = "\(message.displayName) sohbetten yasaklandı. Yasaklılar sekmesinden kaldırabilirsin."
                    } catch {
                        client.notice = AuthErrorMessage.from(error)
                    }
                }
            } label: {
                Label("Sohbetten yasakla", systemImage: "nosign")
            }
        }
    }

    private func pendingBubble(_ message: PendingCommunityMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer(minLength: 48)
            VStack(alignment: .trailing, spacing: 3) {
                Text(message.body)
                    .font(AppTypography.body())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(InkGlass.surface.opacity(0.55))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                if message.failed {
                    HStack(spacing: 10) {
                        Text("Gönderilemedi").foregroundStyle(Color.inkError)
                        Button("Tekrar dene") { client.retry(message) }
                        Button("Sil") { client.discard(message) }
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .buttonStyle(.plain)
                } else {
                    Text("Gönderiliyor…").font(.system(size: 10)).foregroundStyle(InkMockup.captionColor)
                }
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Topluluğa yaz…", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .font(AppTypography.body(size: 16))
                .focused($inputFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .glassChrome(radius: 16)
                .disabled(!client.canSend)

            Button {
                client.send(draft)
                draft = ""
            } label: {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(canSubmit ? InkMockup.accentPink.opacity(0.85) : InkGlass.surface.opacity(0.45))
                    .frame(width: 46, height: 46)
                    .overlay(Image(systemName: "paperplane.fill").foregroundStyle(.white).font(.system(size: 16)))
            }
            .disabled(!canSubmit)
            .accessibilityLabel("Gönder")
        }
        .padding(.horizontal, InkMockup.screenHorizontal)
        .padding(.vertical, 10)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(InkGlass.background.opacity(0.45))
        }
        .overlay(alignment: .topTrailing) {
            if draft.count > client.maxLength - 200 {
                Text("\(draft.count)/\(client.maxLength)")
                    .font(AppTypography.mono(size: 11))
                    .foregroundStyle(draft.count > client.maxLength ? Color.inkError : InkMockup.captionColor)
                    .padding(.trailing, InkMockup.screenHorizontal)
                    .offset(y: -16)
            }
        }
    }

    private var canSubmit: Bool {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return client.canSend && client.state == .online && !trimmed.isEmpty && trimmed.count <= client.maxLength
    }
}

private enum ChatTimelineRow: Identifiable {
    case day(Date)
    case message(CommunityMessage)
    case pending(PendingCommunityMessage)

    var id: String {
        switch self {
        case .day(let date): return "day-\(date.timeIntervalSince1970)"
        case .message(let message): return message.id
        case .pending(let message): return message.id
        }
    }
}

private enum ChatDay {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "tr_TR")
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        return calendar
    }()

    static func title(for date: Date) -> String {
        let today = calendar.startOfDay(for: .now)
        let day = calendar.startOfDay(for: date)
        let gap = calendar.dateComponents([.day], from: day, to: today).day ?? 0
        if gap == 0 { return "Bugün" }
        if gap == 1 { return "Dün" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.timeZone = calendar.timeZone
        if gap < 7 {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}

private struct CommunityRulesSheet: View {
    let onAccept: () -> Void
    let onDecline: () -> Void

    private let rules = [
        ("heart.fill", "Saygılı ol. Hakaret, taciz, nefret söylemi ve ayrımcılık yasaktır."),
        ("photo.badge.exclamationmark", "Müstehcen, şiddet içeren veya yasa dışı içerik paylaşma."),
        ("megaphone.fill", "Spam, reklam ve izinsiz satış yapma."),
        ("lock.shield.fill", "Kendinin veya başkalarının kişisel bilgilerini (telefon, adres vb.) paylaşma."),
        ("exclamationmark.bubble.fill", "Uygunsuz bir mesaj görürsen basılı tutup Bildir'e dokun ya da kullanıcıyı engelle."),
        ("checkmark.seal.fill", "Ink Akademi Crew bildirimleri 24 saat içinde inceler; kurallara uymayan mesajlar silinir ve kullanıcılar sohbetten uzaklaştırılır."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Ink Akademi topluluğuna hoş geldin! Sohbete katılmadan önce kuralları okuyup kabul etmelisin.")
                        .font(AppTypography.body())
                        .foregroundStyle(.secondary)
                    ForEach(rules, id: \.1) { icon, text in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundStyle(InkMockup.accentPink)
                                .frame(width: 26)
                            Text(text).font(AppTypography.body())
                        }
                    }
                    Text("Uygunsuz içeriğe ve kötü niyetli kullanıcılara hiçbir şekilde tolerans gösterilmez.")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(24)
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: onAccept) {
                    Text("Kuralları kabul ediyorum")
                        .font(AppTypography.button())
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
                .padding(20)
                .background(.ultraThinMaterial)
            }
            .studentScreenBackground()
            .navigationTitle("Topluluk kuralları")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", action: onDecline)
                }
            }
        }
    }
}
