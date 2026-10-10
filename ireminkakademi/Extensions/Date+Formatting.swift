import Foundation

extension Date {
    var formatted_ddMMyyyy: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: self)
    }

    var formatted_relative: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: .now)
    }

    var isOverdue: Bool {
        self < Date.now
    }
}
