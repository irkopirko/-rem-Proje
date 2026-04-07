import SwiftUI

// MARK: - Single quiz option button

struct QuizOptionButton: View {
    let label: String
    let index: Int
    let isSelected: Bool
    let isTrueFalse: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {

                // Leading indicator
                if isTrueFalse {
                    Image(systemName: index == 0 ? "checkmark" : "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isSelected ? Color.inkWhite : Color.inkTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(isSelected ? Color.inkBlack : Color.inkSurfaceSecondary)
                        .clipShape(Circle())
                } else {
                    Text(optionLetter)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? Color.inkWhite : Color.inkTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(isSelected ? Color.inkBlack : Color.inkSurfaceSecondary)
                        .clipShape(Circle())
                }

                // Text
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? Color.inkTextPrimary : Color.inkTextSecondary)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Trailing radio
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color.inkBlack : Color.inkBorder)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? Color.inkBlack.opacity(0.04) : Color.inkSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.inkBlack : Color.inkDivider, lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var optionLetter: String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return index < letters.count ? letters[index] : "\(index + 1)"
    }
}

// MARK: - Review state option (for result screen)

struct QuizOptionReview: View {
    let label: String
    let state: OptionState

    enum OptionState {
        case neutral
        case correct
        case wrong
        case correctAnswer  // shows the right answer when user chose wrong
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(textColor)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var iconName: String {
        switch state {
        case .correct, .correctAnswer: return "checkmark.circle.fill"
        case .wrong: return "xmark.circle.fill"
        case .neutral: return "circle"
        }
    }

    private var iconColor: Color {
        switch state {
        case .correct, .correctAnswer: return .inkSuccess
        case .wrong: return .inkError
        case .neutral: return .inkTextTertiary
        }
    }

    private var textColor: Color {
        switch state {
        case .correct, .correctAnswer: return .inkSuccess
        case .wrong: return .inkError
        case .neutral: return .inkTextTertiary
        }
    }

    private var bgColor: Color {
        switch state {
        case .correct, .correctAnswer: return Color.inkSuccess.opacity(0.06)
        case .wrong: return Color.inkError.opacity(0.06)
        case .neutral: return .clear
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        QuizOptionButton(label: "Neolitik Dönem", index: 0, isSelected: false, isTrueFalse: false) {}
        QuizOptionButton(label: "Rönesans", index: 1, isSelected: true, isTrueFalse: false) {}
        QuizOptionButton(label: "Doğru", index: 0, isSelected: true, isTrueFalse: true) {}
        QuizOptionButton(label: "Yanlış", index: 1, isSelected: false, isTrueFalse: true) {}
        Divider()
        QuizOptionReview(label: "Rönesans", state: .wrong)
        QuizOptionReview(label: "Neolitik Dönem", state: .correctAnswer)
    }
    .padding()
}
