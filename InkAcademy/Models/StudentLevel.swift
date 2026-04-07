import Foundation

struct StudentLevel {
    let title: String
    let icon: String

    static func forCompletedLessons(_ completedLessons: Int) -> StudentLevel {
        switch completedLessons {
        case 0:
            return StudentLevel(title: "Başlangıç", icon: "leaf")
        case 1...3:
            return StudentLevel(title: "Çırak", icon: "flame")
        case 4...7:
            return StudentLevel(title: "Orta", icon: "star")
        case 8...12:
            return StudentLevel(title: "İleri", icon: "star.fill")
        default:
            return StudentLevel(title: "Usta", icon: "crown")
        }
    }
}
