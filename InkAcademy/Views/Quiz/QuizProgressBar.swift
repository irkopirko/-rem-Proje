import SwiftUI

// MARK: - Thin quiz progress bar

struct QuizProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: 8) {

            // Question dots
            HStack(spacing: 4) {
                ForEach(0..<total, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(index <= current ? Color.inkBlack : Color.inkDivider)
                        .frame(height: 3)
                }
            }

            // Counter
            HStack {
                Text("Soru \(current + 1)/\(total)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.inkTextSecondary)

                Spacer()
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        QuizProgressBar(current: 0, total: 5)
        QuizProgressBar(current: 2, total: 5)
        QuizProgressBar(current: 4, total: 5)
    }
    .padding()
}
