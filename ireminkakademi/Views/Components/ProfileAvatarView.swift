import PhotosUI
import SwiftUI

/// Profil fotoğrafı; yoksa baş harfler.
struct ProfileAvatarView: View {
    let url: URL?
    let initials: String
    var size: CGFloat = 56
    var frame: AvatarFrame = .gray
    var rank: AcademyRank? = nil
    var showsCameraBadge = false
    var isBusy = false

    var body: some View {
        VStack(spacing: max(3, size * 0.08)) {
            Circle()
                .fill(InkMockup.fieldFill)
                .frame(width: size, height: size)
                .overlay {
                    if let url {
                        AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                placeholder
                            }
                        }
                    } else {
                        placeholder
                    }
                }
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(frameStroke, lineWidth: max(2, size * 0.055)))
                .overlay {
                    if isBusy {
                        Circle().fill(.black.opacity(0.35))
                        ProgressView().tint(.white)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if showsCameraBadge {
                        Image(systemName: "camera.fill")
                            .font(.system(size: size * 0.15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(size * 0.08)
                            .background(Circle().fill(Color.black))
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }

            if let rank {
                RankStarsView(rank: rank, width: size)
            }
        }
        .frame(width: size)
        .accessibilityHidden(true)
    }

    private var frameStroke: some ShapeStyle {
        switch frame {
        case .gold:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.86, blue: 0.42),
                        Color(red: 0.78, green: 0.56, blue: 0.12),
                        Color(red: 0.93, green: 0.75, blue: 0.28),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .purple:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.72, green: 0.42, blue: 0.92),
                        Color(red: 0.42, green: 0.16, blue: 0.68),
                        Color(red: 0.58, green: 0.28, blue: 0.82),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .gray:
            return AnyShapeStyle(Color(white: 0.62))
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if initials.isEmpty {
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundStyle(InkMockup.captionColor)
        } else {
            Text(initials)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(InkMockup.textPrimary)
        }
    }
}

struct RankStarsView: View {
    let rank: AcademyRank
    var width: CGFloat = 56

    var body: some View {
        HStack(spacing: max(1, width * 0.04)) {
            ForEach(0..<rank.starCount, id: \.self) { _ in
                Image(systemName: "star.fill")
            }
        }
        .font(.system(size: max(9, width * 0.2)))
        .foregroundStyle(
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.86, blue: 0.42),
                    Color(red: 0.86, green: 0.64, blue: 0.18),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(width: width)
        .accessibilityLabel(rank.label)
    }
}

enum ProfilePhotoProcessor {
    static let side: CGFloat = 512

    /// Ortadan kare kırpar, 512 px'e küçültür ve JPEG olarak yeniden kodlar (EXIF/GPS bilgisi atılır).
    static func jpegData(from raw: Data) -> Data? {
        guard let image = UIImage(data: raw), image.size.width > 0, image.size.height > 0 else { return nil }
        let scale = side / min(image.size.width, image.size.height)
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(x: (side - drawSize.width) / 2, y: (side - drawSize.height) / 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
        return rendered.jpegData(compressionQuality: 0.85)
    }
}

/// Profil fotoğrafını değiştirme/kaldırma; dokununca seçenekler açılır.
struct EditableProfileAvatar: View {
    let container: DIContainer
    var size: CGFloat = 84

    @State private var showOptions = false
    @State private var showPicker = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var isWorking = false
    @State private var errorMessage: String?

    private var user: User? { container.sessionUser }

    var body: some View {
        Button { showOptions = true } label: {
            ProfileAvatarView(
                url: user?.profilePhotoURL,
                initials: user?.initials ?? "",
                size: size,
                frame: user?.avatarFrame ?? .gray,
                rank: user?.levelProgress.rank,
                showsCameraBadge: true,
                isBusy: isWorking
            )
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
        .accessibilityLabel("Profil fotoğrafını değiştir")
        .confirmationDialog("Profil fotoğrafı", isPresented: $showOptions, titleVisibility: .visible) {
            Button(user?.profilePhotoURL == nil ? "Fotoğraf seç" : "Fotoğrafı değiştir") { showPicker = true }
            if user?.profilePhotoURL != nil {
                Button("Fotoğrafı kaldır", role: .destructive) { Task { await remove() } }
            }
            Button("Vazgeç", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await upload(item) }
        }
        .alert("Fotoğraf güncellenemedi", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func upload(_ item: PhotosPickerItem) async {
        isWorking = true
        defer {
            isWorking = false
            pickerItem = nil
        }
        do {
            guard let raw = try await item.loadTransferable(type: Data.self),
                  let jpeg = ProfilePhotoProcessor.jpegData(from: raw) else {
                errorMessage = "Seçilen fotoğraf okunamadı."
                return
            }
            container.updateSessionUser(try await container.authService.updateProfilePhoto(jpegData: jpeg))
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }

    private func remove() async {
        isWorking = true
        defer { isWorking = false }
        do {
            container.updateSessionUser(try await container.authService.removeProfilePhoto())
        } catch {
            errorMessage = AuthErrorMessage.from(error)
        }
    }
}
