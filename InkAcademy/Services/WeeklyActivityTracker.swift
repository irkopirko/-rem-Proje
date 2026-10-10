import Foundation

/// Haftalık oyun / aktivite serisi — ana sayfadaki oyunlarla uyumlu basit takip.
enum WeeklyActivityTracker {
    private static let key = "ink.weeklyActivity.playDates"

    static var currentStreakDays: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var cursor = today
        let played = playDates
        while played.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    static func recordPlayToday() {
        let day = Calendar.current.startOfDay(for: Date())
        var set = Set(playDates)
        set.insert(day)
        let sorted = set.sorted()
        UserDefaults.standard.set(sorted.map { $0.timeIntervalSince1970 }, forKey: key)
    }

    private static var playDates: Set<Date> {
        let raw = UserDefaults.standard.array(forKey: key) as? [TimeInterval] ?? []
        let calendar = Calendar.current
        return Set(raw.map { calendar.startOfDay(for: Date(timeIntervalSince1970: $0)) })
    }
}
