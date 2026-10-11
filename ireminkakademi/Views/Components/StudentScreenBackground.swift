import SwiftUI

struct StudentScreenBackgroundModifier: ViewModifier {
    @Environment(\.inkStudioChrome) private var studio

    func body(content: Content) -> some View {
        if studio {
            content.background { GlassBackground() }
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
