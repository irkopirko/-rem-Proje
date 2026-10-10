import SwiftUI

struct ObjectMarker: View {
    let object: PlacedHiddenObject
    let sceneSize: CGSize

    var body: some View {
        let size = object.frameSize(in: sceneSize)
        Image(object.type.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .rotationEffect(.degrees(object.rotation))
            .position(
                x: object.center.x * sceneSize.width,
                y: object.center.y * sceneSize.height
            )
            .opacity(object.isFound ? 0.35 : 1)
            .overlay {
                if object.isHighlighted {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.inkSage, lineWidth: 3)
                        .frame(width: size.width * 1.1, height: size.height * 1.1)
                        .position(
                            x: object.center.x * sceneSize.width,
                            y: object.center.y * sceneSize.height
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: object.isHighlighted)
            .allowsHitTesting(false)
    }
}
