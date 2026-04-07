import SwiftUI

// MARK: - Expandable lesson notes card

struct LessonNotesCard: View {
    let text: String
    @State private var isExpanded = false

    private let collapsedLineLimit = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header
            HStack {
                Label("Ders Notları", systemImage: "doc.text")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.inkTextPrimary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.inkTextTertiary)
                }
            }

            // Content
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.inkTextSecondary)
                .lineSpacing(5)
                .lineLimit(isExpanded ? nil : collapsedLineLimit)
                .animation(.easeInOut(duration: 0.25), value: isExpanded)

            if !isExpanded {
                Text("Devamını oku")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.inkBlack)
            }
        }
        .padding(18)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.inkDivider, lineWidth: 0.5)
        )
    }
}

#Preview {
    LessonNotesCard(
        text: "Dövme sanatının dünya genelindeki tarihsel gelişimini keşfedin. Antik Mısır'dan Polinezya'ya, Japonya'dan modern Batı kültürüne kadar dövmenin toplumsal ve sanatsal anlamını inceleyin. Bu ders, dövme sanatının kökenlerini ve evrimini derinlemesine ele alır."
    )
    .padding()
    .background(Color.inkBackground)
}
