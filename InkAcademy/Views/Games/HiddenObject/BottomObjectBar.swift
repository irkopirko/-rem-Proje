import SwiftUI

struct BottomObjectBar: View {
    let foundTypes: Set<HiddenObjectType>

    var body: some View {
        HStack(spacing: 16) {
            ForEach(HiddenObjectType.allCases) { type in
                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.inkSurface.opacity(0.9))
                            .frame(width: 72, height: 72)

                        Image(type.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .opacity(foundTypes.contains(type) ? 0.25 : 1)

                        if foundTypes.contains(type) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.inkSage)
                        }
                    }

                    Text(type.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.inkTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 80)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    BottomObjectBar(foundTypes: [.machine])
        .padding()
        .inkPageBackground()
}
