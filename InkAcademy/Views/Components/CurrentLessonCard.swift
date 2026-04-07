import SwiftUI

// MARK: - Current Lesson Card (hero card for continue-learning)

struct CurrentLessonCard: View {
    let moduleName: String
    let lesson: Lesson
    let moduleProgress: Double
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.inkTeal)
                                .frame(width: 6, height: 6)

                            Text(moduleName.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.inkTextSecondary)
                                .tracking(0.8)
                        }

                        Text(lesson.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.inkTextPrimary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    lessonArtwork
                }
                .padding(.bottom, 14)

                // Meta
                HStack(spacing: 12) {
                    Label("Ders \(lesson.order)", systemImage: "book")
                    Label(lesson.formattedDuration, systemImage: "clock")
                    if lesson.videoURL != nil {
                        Label("Video", systemImage: "play.fill")
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkTextTertiary)
                .padding(.bottom, 16)

                // Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.inkDivider)
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.inkTeal)
                                .frame(width: geo.size.width * CGFloat(min(moduleProgress, 1.0)), height: 4)
                                .animation(.easeInOut(duration: 0.4), value: moduleProgress)
                        }
                    }
                    .frame(height: 4)

                    HStack {
                        Text("Modül ilerlemesi")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.inkTextTertiary)
                        Spacer()
                        Text("\(Int(moduleProgress * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.inkTeal)
                    }
                }

                // Continue button
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Devam Et")
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Color.inkWhite)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(Color.inkAccent)
                    .clipShape(Capsule())
                }
                .padding(.top, 16)
            }
        }
        .buttonStyle(.plain)
    }

    private var lessonArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadii.lg, style: .continuous)
                .fill(Color.inkTealSoft)
                .frame(width: 72, height: 72)

            Image(systemName: lesson.videoURL != nil ? "play.square.fill" : "book.pages.fill")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(Color.inkTeal)
        }
    }
}

#Preview {
    CurrentLessonCard(
        moduleName: "Dövme Sanatına Giriş",
        lesson: Lesson(
            id: "1",
            title: "Hijyen ve Güvenlik",
            videoURL: URL(string: "https://example.com"),
            duration: 540,
            order: 2,
            isCompleted: false,
            description: ""
        ),
        moduleProgress: 0.33
    )
    .padding(AppSpacing.cardInner)
    .premiumCard()
    .padding()
    .background(Color.inkBackground)
}