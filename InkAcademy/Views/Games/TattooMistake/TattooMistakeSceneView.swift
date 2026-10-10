import SwiftUI

struct TattooMistakeSceneView: View {
    let challenge: TattooMistakeChallenge
    let foundMistakeIDs: Set<UUID>
    let highlightedMistakeID: UUID?
    let wrongTapPoint: CGPoint?
    let showWrongTap: Bool
    let revealAllMistakes: Bool
    let onTap: (CGPoint, CGSize) -> Void

    var body: some View {
        GeometryReader { geo in
            Image(challenge.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                .frame(width: geo.size.width, height: geo.size.height)
                .accessibilityLabel("Dövme görseli, hatalı bölgeleri bul")
                .overlay {
                    GeometryReader { sceneGeo in
                        let sceneSize = sceneGeo.size

                        ZStack {
                            ForEach(challenge.mistakes) { mistake in
                                if revealAllMistakes, !foundMistakeIDs.contains(mistake.id) {
                                    MistakeRegionOverlay(
                                        mistake: mistake,
                                        sceneSize: sceneSize,
                                        style: .answerReveal
                                    )
                                }

                                if highlightedMistakeID == mistake.id {
                                    MistakeRegionOverlay(
                                        mistake: mistake,
                                        sceneSize: sceneSize,
                                        style: .foundHighlight
                                    )
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(Color.inkSage)
                                        .position(
                                            x: mistake.rect(in: sceneSize).midX,
                                            y: mistake.rect(in: sceneSize).midY
                                        )
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }

                            if showWrongTap, let wrongTapPoint {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(Color.inkError)
                                    .position(wrongTapPoint)
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onEnded { value in
                                    guard !revealAllMistakes else { return }
                                    let point = value.location
                                    guard point.x >= 0, point.y >= 0,
                                          point.x <= sceneSize.width,
                                          point.y <= sceneSize.height else { return }
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

#Preview {
    TattooMistakeSceneView(
        challenge: TattooMistakeChallengeCatalog.mainChallenge,
        foundMistakeIDs: [],
        highlightedMistakeID: nil,
        wrongTapPoint: nil,
        showWrongTap: false,
        revealAllMistakes: false
    ) { _, _ in }
    .frame(height: 420)
    .padding()
    .inkPageBackground()
}
