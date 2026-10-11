import Foundation

@Observable
final class BadgeUnlockStore {
    static let shared = BadgeUnlockStore()

    private(set) var presented: BadgeDTO?
    private var queue: [BadgeDTO] = []
    private var seen: Set<String>
    private let seenKey = "ink.badges.seenSlugs"

    private init() {
        seen = Set(UserDefaults.standard.stringArray(forKey: seenKey) ?? [])
    }

    func ingest(_ progress: BadgeProgressResponse) {
        if let flagged = progress.newlyEarned {
            for badge in flagged where !seen.contains(badge.slug) {
                enqueue(badge)
            }
        }
        for badge in progress.badges where badge.isEarned && !seen.contains(badge.slug) {
            if badge.wasJustEarned {
                enqueue(badge)
            } else {
                seen.insert(badge.slug)
            }
        }
        persist()
        presentNextIfNeeded()
    }

    func dismiss() {
        presented = nil
        presentNextIfNeeded()
    }

    private func enqueue(_ badge: BadgeDTO) {
        seen.insert(badge.slug)
        if presented?.slug != badge.slug, !queue.contains(where: { $0.slug == badge.slug }) {
            queue.append(badge)
        }
    }

    private func presentNextIfNeeded() {
        guard presented == nil, !queue.isEmpty else { return }
        presented = queue.removeFirst()
    }

    private func persist() {
        UserDefaults.standard.set(Array(seen), forKey: seenKey)
    }
}

extension BadgeDTO {
    var earnedDate: Date? {
        guard let earnedAt else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: earnedAt) { return date }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: earnedAt)
    }

    var wasJustEarned: Bool {
        guard let earnedDate else { return false }
        return Date().timeIntervalSince(earnedDate) < 180
    }
}
