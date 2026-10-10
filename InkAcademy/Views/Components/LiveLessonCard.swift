import SwiftUI

struct LiveLessonCard: View {
    var session: LiveSession?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadii.sm, style: .continuous)
                    .fill(Color.inkSurfaceSecondary)
                    .frame(width: 44, height: 44)

                Image(systemName: "video.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.inkTextTertiary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(session?.title ?? "Canlı yayın")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkTextPrimary)

                if let session {
                    Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.inkTextSecondary)
                    Text(session.instructorName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.inkTextTertiary)
                } else {
                    Text("Yakında aktif olacak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.inkTextTertiary)
                }
            }

            Spacer()

            Text(session == nil ? "Yakında" : "Katıl")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(session == nil ? Color.inkTextTertiary : Color.inkAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.inkAccentSoft.opacity(session == nil ? 0.2 : 0.45))
                .clipShape(Capsule())
        }
        .padding(AppSpacing.lg)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous)
                .stroke(Color.inkBorder, lineWidth: 1)
        )
        .opacity(session == nil ? 0.65 : 1)
    }
}

#Preview {
    LiveLessonCard(session: LiveSession(
        id: "1",
        title: "Packing Q&A",
        description: "Demo",
        startDate: .now,
        instructorName: "Usta Deniz",
        meetingURL: nil,
        isReplayAvailable: false,
        replayURL: nil
    ))
    .padding()
    .background(Color.inkBackground)
}
