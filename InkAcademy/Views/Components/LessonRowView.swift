import SwiftUI

struct LessonRowView: View {
    let lesson: Lesson
    let index: Int
    var isLocked: Bool = false

    var body: some View {
        HStack(spacing: 14) {

            // Order indicator
            ZStack {
                Circle()
                    .fill(circleFill)
                    .frame(width: 36, height: 36)

                circleContent
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isLocked ? Color.inkTextTertiary : Color.inkTextPrimary)

                HStack(spacing: 10) {
                    Label(lesson.formattedDuration, systemImage: "clock")
                    if lesson.videoURL != nil {
                        Label("Video", systemImage: "play.fill")
                    }
                }
                .font(.caption2)
                .foregroundStyle(Color.inkTextTertiary)
            }

            Spacer()

            // Trailing icon
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkTextTertiary)
            } else if lesson.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.inkSuccess)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.inkTextTertiary)
            }
        }
        .padding(.vertical, 10)
        .opacity(isLocked ? 0.5 : 1.0)
    }

    // MARK: - Helpers

    private var circleFill: Color {
        if isLocked { return Color.inkSurfaceSecondary }
        if lesson.isCompleted { return Color.inkSuccess }
        return Color.inkSurfaceSecondary
    }

    @ViewBuilder
    private var circleContent: some View {
        if lesson.isCompleted && !isLocked {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        } else {
            Text("\(index)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isLocked ? Color.inkTextTertiary : Color.inkTextPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        LessonRowView(
            lesson: Lesson(id: "1", title: "Dövme Tarihçesi", videoURL: URL(string: "https://example.com"), duration: 720, order: 1, isCompleted: true, description: ""),
            index: 1
        )
        Divider().padding(.leading, 50)
        LessonRowView(
            lesson: Lesson(id: "2", title: "Hijyen ve Güvenlik", videoURL: URL(string: "https://example.com"), duration: 540, order: 2, isCompleted: false, description: ""),
            index: 2
        )
        Divider().padding(.leading, 50)
        LessonRowView(
            lesson: Lesson(id: "3", title: "Gölgelendirme", videoURL: nil, duration: 840, order: 3, isCompleted: false, description: ""),
            index: 3,
            isLocked: true
        )
    }
    .padding()
}
