import SwiftUI

struct BottomObjectBar: View {
    let foundTypes: Set<HiddenObjectType>
    let imageSet: HiddenObjectImageSet

    var body: some View {
        HStack(spacing: 16) {
            ForEach(HiddenObjectType.allCases) { type in
                let found = foundTypes.contains(type)
                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.inkSurface.opacity(0.92))
                            .frame(width: 72, height: 72)

                        Image(type.assetName(in: imageSet))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .opacity(found ? 0.2 : 1)

                        if found {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.inkSage)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Text(type.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.inkTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 80)
                }
                .animation(.easeInOut(duration: 0.25), value: found)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
