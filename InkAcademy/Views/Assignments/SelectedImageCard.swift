import SwiftUI

// MARK: - Selected image thumbnail with remove action

struct SelectedImageCard: View {
    let imageData: Data
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(10)
        }
    }
}

#Preview {
    // Can't show real image in preview without data, just structure test
    let sampleData = Data()
    SelectedImageCard(imageData: sampleData, onRemove: {})
        .padding()
}
