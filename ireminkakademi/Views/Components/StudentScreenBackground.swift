import SwiftUI

struct StudentScreenBackgroundModifier: ViewModifier {
    @Environment(\.inkStudioChrome) private var studio

    func body(content: Content) -> some View {
        if studio {
            content.background {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.09, green: 0.05, blue: 0.07),
                            Color(red: 0.04, green: 0.03, blue: 0.05),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    RadialGradient(
                        colors: [InkMockup.accentPink.opacity(0.18), .clear],
                        center: .top,
                        startRadius: 20,
                        endRadius: 380
                    )
                }
                .ignoresSafeArea()
            }
        } else {
            content.inkImageBackground("sec_background")
        }
    }
}

extension View {
    func studentScreenBackground() -> some View {
        modifier(StudentScreenBackgroundModifier())
    }
}
