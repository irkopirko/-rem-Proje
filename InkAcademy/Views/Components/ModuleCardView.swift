import SwiftUI

struct ModuleCardView: View {
    let module: TrainingModule

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Artwork + XP
            HStack(alignment: .top) {
                moduleArtwork

                Spacer()

                if !module.isLocked {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(isComplete ? "Bitirildi" : "XP")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.inkTextTertiary)
                        Text(isComplete ? "100" : "\(xpReward)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(moduleAccentColor)
                    }
                }
            }
            .padding(.bottom, 14)

            // Status badge + lesson count
            HStack(alignment: .center) {
                statusBadge
                Spacer()
                Text("\(module.lessons.count) ders")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.inkTextTertiary)
            }
            .padding(.bottom, 10)

            // Title
            Text(module.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(module.isLocked ? Color.inkTextTertiary : Color.inkTextPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .padding(.bottom, 4)

            // Description
            Text(module.description)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.inkTextTertiary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 14)

            Spacer(minLength: 0)

            // Progress bar
            if !module.isLocked {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.inkDivider)
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(moduleAccentColor)
                                .frame(
                                    width: geo.size.width * CGFloat(min(module.progressPercent, 1.0)),
                                    height: 4
                                )
                        }
                    }
                    .frame(height: 4)

                    Text(progressLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(moduleAccentColor)
                }
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Kilitli")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.inkTextTertiary)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous)
                .stroke(module.isLocked ? Color.inkBorder : moduleAccentColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(module.isLocked ? 0.02 : 0.05), radius: AppShadows.softRadius, x: 0, y: AppShadows.softY)
        .opacity(module.isLocked ? 0.6 : 1.0)
    }

    // MARK: - Helpers

    private var isComplete: Bool {
        module.progressPercent >= 1.0
    }

    private var progressLabel: String {
        if isComplete { return "Tamamlandı" }
        let pct = Int(module.progressPercent * 100)
        return pct > 0 ? "%\(pct) tamamlandı" : "Başlanmadı"
    }

    private var xpReward: Int {
        max(module.lessons.count * 25, 50)
    }

    private var moduleAccentColor: Color {
        if module.isLocked { return .inkTextTertiary }
        if isComplete { return .inkSage }
        return .inkTeal
    }

    private var moduleArtwork: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: module.isLocked
                            ? [Color.inkSurfaceSecondary, Color.inkWhite]
                            : [moduleAccentColor.opacity(0.15), Color.inkAccentSoft],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 68, height: 58)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                        .stroke(moduleAccentColor.opacity(module.isLocked ? 0.08 : 0.15), lineWidth: 1)
                )

            Image(systemName: artworkSymbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(moduleAccentColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 68, height: 58)
    }

    private var artworkSymbol: String {
        switch module.id {
        case "module-1": return "book.pages.fill"
        case "module-2": return "syringe.fill"
        case "module-3": return "scribble.variable"
        case "module-4": return "cross.case.fill"
        case "module-5": return "square.on.circle"
        case "module-6": return "paintpalette.fill"
        case "module-7": return "person.crop.rectangle.stack.fill"
        default: return module.isLocked ? "lock.fill" : "sparkles"
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if module.isLocked {
            badgeCapsule(text: "Kilitli", icon: "lock.fill", fg: Color.inkTextTertiary, bg: Color.inkSurfaceSecondary)
        } else if isComplete {
            badgeCapsule(text: "Tamamlandı", icon: "checkmark", fg: Color.inkSage, bg: Color.inkSageSoft)
        } else if module.progressPercent > 0 {
            badgeCapsule(text: "Devam Ediyor", icon: "play.fill", fg: Color.inkTeal, bg: Color.inkTealSoft)
        } else {
            badgeCapsule(text: "Yeni", icon: nil, fg: Color.inkRose, bg: Color.inkRoseSoft)
        }
    }

    private func badgeCapsule(text: String, icon: String?, fg: Color, bg: Color) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .bold))
            }
            Text(text)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(bg)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            ModuleCardView(module: TrainingModule(
                id: "1", title: "Dövme Sanatına Giriş",
                description: "Temel bilgiler ve güvenlik kuralları",
                imageURL: nil,
                lessons: [
                    Lesson(id: "1", title: "A", videoURL: nil, duration: 720, order: 1, isCompleted: true, description: ""),
                    Lesson(id: "2", title: "B", videoURL: nil, duration: 540, order: 2, isCompleted: false, description: "")
                ],
                isLocked: false
            ))
            ModuleCardView(module: TrainingModule(
                id: "2", title: "Gölgelendirme",
                description: "İleri seviye teknikler",
                imageURL: nil, lessons: [], isLocked: true
            ))
        }
    }
    .padding()
    .background(Color.inkBackground)
}