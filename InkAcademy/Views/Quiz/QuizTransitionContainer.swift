import SwiftUI

enum QuizTransitionDirection {
    case forward
    case backward
}

struct QuizTransitionContainer<Content: View>: View {
    let id: Int
    let direction: QuizTransitionDirection
    let content: Content

    init(id: Int, direction: QuizTransitionDirection, @ViewBuilder content: () -> Content) {
        self.id = id
        self.direction = direction
        self.content = content()
    }

    var body: some View {
        content
            .id(id)
            .transition(transition)
            .animation(.easeInOut(duration: 0.25), value: id)
    }

    private var transition: AnyTransition {
        let offset: CGFloat = direction == .forward ? 8 : -8
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(y: offset)),
            removal: .opacity.combined(with: .offset(y: -offset))
        )
    }
}

#Preview {
    QuizTransitionContainer(id: 1, direction: .forward) {
        Text("Soru 1")
            .font(.title2.weight(.semibold))
    }
    .padding()
    .background(Color.inkBackground)
}
