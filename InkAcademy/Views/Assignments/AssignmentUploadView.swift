import SwiftUI
import PhotosUI

struct AssignmentUploadView: View {
    @Bindable var viewModel: AssignmentUploadViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // 1 — Assignment info
                    assignmentHeader

                    // 2 — Image picker
                    imageSection

                    // 3 — Note
                    noteSection

                    // 4 — Submit
                    submitSection

                    // 5 — State feedback
                    feedbackSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
                .animation(.easeInOut(duration: 0.25), value: viewModel.uploadState)
            }
            .background(Color.inkBackground)
            .navigationTitle("Ödev Yükle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(Color.inkTextSecondary)
                }
            }
            .interactiveDismissDisabled(viewModel.isUploading)
        }
    }

    // MARK: - 1. Header

    private var assignmentHeader: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                StatusBadgeView(status: viewModel.assignment.status)
                Spacer()
                Label(viewModel.assignment.dueDate.formatted_ddMMyyyy, systemImage: "calendar")
                    .font(.caption2)
                    .foregroundStyle(
                        viewModel.assignment.dueDate.isOverdue ? Color.inkError : Color.inkTextTertiary
                    )
            }

            Text(viewModel.assignment.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.inkTextPrimary)

            Text(viewModel.assignment.description)
                .font(.subheadline)
                .foregroundStyle(Color.inkTextSecondary)
                .lineSpacing(4)
        }
        .padding(18)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.inkDivider, lineWidth: 0.5)
        )
    }

    // MARK: - 2. Image

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            SectionHeaderView(text: "Fotoğraf")

            if let data = viewModel.imageData {
                // Show selected image
                SelectedImageCard(imageData: data) {
                    withAnimation { viewModel.removeImage() }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                // Picker button
                PhotosPicker(
                    selection: $viewModel.selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.inkSurfaceSecondary)
                                .frame(width: 44, height: 44)

                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.inkTextSecondary)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Fotoğraf Seç")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.inkTextPrimary)

                            Text("Galeriden bir fotoğraf seçin")
                                .font(.caption)
                                .foregroundStyle(Color.inkTextTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.inkTextTertiary)
                    }
                    .padding(16)
                    .background(Color.inkSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.inkDivider, lineWidth: 0.5)
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.imageData != nil)
    }

    // MARK: - 3. Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(text: "Not (opsiyonel)")

            TextField("Eğitmene not bırakın...", text: $viewModel.note, axis: .vertical)
                .font(.subheadline)
                .lineLimit(3...6)
                .padding(14)
                .background(Color.inkSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.inkDivider, lineWidth: 0.5)
                )
        }
    }

    // MARK: - 4. Submit

    private var submitSection: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isUploading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                }
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 15, weight: .medium))
                Text("Gönder")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(viewModel.canSubmit ? Color.inkBlack : Color.inkTextTertiary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!viewModel.canSubmit)
    }

    // MARK: - 5. Feedback

    @ViewBuilder
    private var feedbackSection: some View {
        switch viewModel.uploadState {
        case .success:
            SuccessStateView(
                title: "Ödev başarıyla gönderildi",
                message: "Eğitmeniniz değerlendirecektir"
            )
            .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .error:
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.inkError)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Gönderim başarısız")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.inkTextPrimary)
                    if let msg = viewModel.errorMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(Color.inkTextTertiary)
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(Color.inkError.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.inkError.opacity(0.2), lineWidth: 0.5)
            )
            .transition(.opacity.combined(with: .move(edge: .bottom)))

        default:
            EmptyView()
        }
    }

}

// MARK: - Preview

#Preview {
    AssignmentUploadView(viewModel: AssignmentUploadViewModel(
        assignment: Assignment(
            id: "1",
            title: "İlk Dövme Tasarımı",
            description: "Basit bir çiçek veya geometrik şekil tasarımı çizin ve fotoğrafını yükleyin.",
            dueDate: .now.addingTimeInterval(86400 * 5),
            submissionDate: nil,
            fileURL: nil,
            status: .pending,
            feedback: nil
        ),
        assignmentService: MockAssignmentService()
    ))
}
