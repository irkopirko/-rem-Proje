import Foundation

/// Bildirim tercihleri — yerel saklama; Supabase `profiles` ile senkron eklenebilir.
@Observable
final class NotificationPreferencesStore {
    private enum Key {
        static let announcements = "ink.notify.announcements"
        static let homework = "ink.notify.homework"
        static let messages = "ink.notify.messages"
    }

    var announcementsEnabled: Bool {
        didSet { UserDefaults.standard.set(announcementsEnabled, forKey: Key.announcements) }
    }

    var homeworkEnabled: Bool {
        didSet { UserDefaults.standard.set(homeworkEnabled, forKey: Key.homework) }
    }

    var messagesEnabled: Bool {
        didSet { UserDefaults.standard.set(messagesEnabled, forKey: Key.messages) }
    }

    init() {
        let d = UserDefaults.standard
        announcementsEnabled = d.object(forKey: Key.announcements) as? Bool ?? true
        homeworkEnabled = d.object(forKey: Key.homework) as? Bool ?? true
        messagesEnabled = d.object(forKey: Key.messages) as? Bool ?? true
    }
}
