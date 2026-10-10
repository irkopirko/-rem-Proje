import SwiftUI
import PhotosUI

/// Crew düzenleme ekranlarında görsel ekleme/çıkarma durumunu tutar (ürün ve ödev ortak).
@Observable
final class CrewImageEditingModel {
    struct PendingImage: Identifiable {
        let id = UUID()
        let jpegData: Data
        let preview: UIImage
    }

    static let maxImages = 30

    var existing: [ProductImageDTO] = []
    var removedIds: Set<String> = []
    var pending: [PendingImage] = []
    var isImporting = false

    var visibleExisting: [ProductImageDTO] { existing.filter { !removedIds.contains($0.id) } }
    var totalCount: Int { visibleExisting.count + pending.count }
    var remainingSlots: Int { max(0, Self.maxImages - totalCount) }

    func importPicked(_ items: [PhotosPickerItem]) async {
        isImporting = true
        defer { isImporting = false }
        for item in items.prefix(remainingSlots) {
            guard let raw = try? await item.loadTransferable(type: Data.self),
                  let jpeg = ProductImageProcessor.jpegData(from: raw),
                  let preview = UIImage(data: jpeg) else { continue }
            pending.append(PendingImage(jpegData: jpeg, preview: preview))
        }
    }

    /// Silinenleri siler, bekleyenleri sırayla yükler. Yarıda kalırsa tekrar çağrıldığında kaldığı yerden devam eder.
    func commit(
        delete: (String) async throws -> Void,
        upload: (Data) async throws -> ProductImageDTO,
        progress: (Int, Int) -> Void
    ) async throws {
        for id in removedIds {
            try await delete(id)
            removedIds.remove(id)
            existing.removeAll { $0.id == id }
        }
        let total = pending.count
        var done = 0
        while let image = pending.first {
            done += 1
            progress(done, total)
            existing.append(try await upload(image.jpegData))
            pending.removeFirst()
        }
    }
}

struct CrewEditorSection<Content: View>: View {
    let title: String
    var footer: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(InkMockup.textPrimary)
            content
            if let footer {
                Text(footer)
                    .font(.system(size: 12))
                    .foregroundStyle(InkMockup.captionColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CrewTextField: View {
    let placeholder: String
    @Binding var text: String
    var font: Font = .system(size: 17)
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        TextField(text: $text, prompt: Text(placeholder).foregroundStyle(InkMockup.placeholderColor)) {
            Text(placeholder)
        }
        .font(font)
        .foregroundStyle(InkMockup.textPrimary)
        .keyboardType(keyboard)
        .textInputAutocapitalization(autocapitalization)
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .background(InkMockup.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(InkMockup.fieldBorder, lineWidth: 1))
    }
}

/// Uzun açıklamalar için büyüyen metin alanı.
struct CrewLongTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var limit: Int
    var minHeight: CGFloat = 240

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .foregroundStyle(InkMockup.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: minHeight)
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundStyle(InkMockup.placeholderColor)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
            .background(InkMockup.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(InkMockup.fieldBorder, lineWidth: 1))

            Text("\(text.count)/\(limit)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(text.count > limit ? Color.inkError : InkMockup.captionColor)
        }
    }
}

/// Görsel ızgarası: mevcut + yeni görseller ve "Fotoğraf ekle" kutusu.
struct CrewImageGrid: View {
    @Bindable var model: CrewImageEditingModel
    @State private var pickerItems: [PhotosPickerItem] = []

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(model.visibleExisting.enumerated()), id: \.element.id) { index, image in
                tile(isCover: index == 0) {
                    ProductImageView(url: image.resolvedURL)
                } onRemove: {
                    model.removedIds.insert(image.id)
                }
            }
            ForEach(Array(model.pending.enumerated()), id: \.element.id) { index, image in
                tile(isCover: model.visibleExisting.isEmpty && index == 0) {
                    Image(uiImage: image.preview).resizable().scaledToFill()
                } onRemove: {
                    model.pending.removeAll { $0.id == image.id }
                }
            }
            if model.remainingSlots > 0 {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: model.remainingSlots,
                    selectionBehavior: .ordered,
                    matching: .images
                ) {
                    addTile
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                await model.importPicked(items)
                pickerItems = []
            }
        }
    }

    private var addTile: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            .foregroundStyle(InkMockup.captionColor.opacity(0.6))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if model.isImporting {
                    ProgressView()
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus").font(.system(size: 24))
                        Text("Fotoğraf ekle").font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(InkMockup.captionColor)
                }
            }
            .accessibilityLabel("Fotoğraf ekle")
    }

    private func tile<Content: View>(isCover: Bool, @ViewBuilder _ content: () -> Content, onRemove: @escaping () -> Void) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay { content() }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.6))
                }
                .buttonStyle(.plain)
                .padding(5)
                .accessibilityLabel("Görseli kaldır")
            }
            .overlay(alignment: .bottomLeading) {
                if isCover {
                    Text("Kapak")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.6), in: Capsule())
                        .padding(6)
                }
            }
    }
}

/// Kaydetme sırasında altta görünen ilerleme etiketi.
struct CrewProgressBadge: View {
    let text: String?

    var body: some View {
        if let text {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 16)
        }
    }
}
