import SwiftUI

struct ObjectMarker: View {
    let object: PlacedHiddenObject
    let sceneSize: CGSize
    let imageSet: HiddenObjectImageSet

    var body: some View {
        let size = object.frameSize(in: sceneSize)
        let position = CGPoint(
            x: object.center.x * sceneSize.width,
            y: object.center.y * sceneSize.height
        )

        Image(object.type.assetName(in: imageSet))
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .rotationEffect(.degrees(object.rotation))
            .scaleEffect(object.isHighlighted ? 1.08 : 1)
            .opacity(object.isFound ? 0 : 1)
            .position(x: position.x, y: position.y)
            .overlay {
                if object.isHighlighted {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.inkSage, lineWidth: 3)
                        .frame(width: size.width * 1.15, height: size.height * 1.15)
                        .position(x: position.x, y: position.y)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: object.isHighlighted)
            .animation(.easeOut(duration: 0.35), value: object.isFound)
            .allowsHitTesting(false)
    }
}
