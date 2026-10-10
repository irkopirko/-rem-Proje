import SwiftUI

struct GameScene: View {
    let objects: [PlacedHiddenObject]
    let wrongTapPoint: CGPoint?
    let showWrongTap: Bool
    let onTap: (CGPoint, CGSize) -> Void

    var body: some View {
        GeometryReader { geo in
            Image(HiddenObjectGameConfig.sceneAsset)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                .frame(width: geo.size.width, height: geo.size.height)
                .overlay {
                    GeometryReader { sceneGeo in
                        let sceneSize = sceneGeo.size

                        ZStack {
                            ForEach(objects) { object in
                                ObjectMarker(object: object, sceneSize: sceneSize)
                            }

                            if showWrongTap, let wrongTapPoint {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(Color.inkError)
                                    .position(wrongTapPoint)
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onEnded { value in
                                    guard sceneSize.width > 0, sceneSize.height > 0 else { return }
                                    let point = value.location
                                    guard point.x >= 0, point.y >= 0,
                                          point.x <= sceneSize.width, point.y <= sceneSize.height else { return }
                                    onTap(point, sceneSize)
                                }
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        }
    }
}
