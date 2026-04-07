import Foundation
import PhotosUI
import SwiftUI

@Observable
final class AssignmentUploadViewModel {

    // MARK: - Assignment context

    let assignment: Assignment

    // MARK: - Input

    var selectedItem: PhotosPickerItem? = nil {
        didSet { Task { await loadImage() } }
    }
    var imageData: Data?
    var note: String = ""

    // MARK: - State

    var uploadState: UploadState = .idle
    var errorMessage: String?

    // MARK: - Dependencies

    private let assignmentService: AssignmentServiceProtocol

    // MARK: - Init

    init(assignment: Assignment, assignmentService: AssignmentServiceProtocol) {
        self.assignment = assignment
        self.assignmentService = assignmentService
    }

    // MARK: - Computed

    var hasImage: Bool { imageData != nil }

    var canSubmit: Bool {
        hasImage && uploadState != .uploading
    }

    var isUploading: Bool { uploadState == .uploading }

    // MARK: - Load image from PhotosPicker

    @MainActor
    private func loadImage() async {
        guard let item = selectedItem else { return }
        imageData = nil

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                imageData = data
                // Reset any previous error/success when new image selected
                if uploadState == .error || uploadState == .success {
                    uploadState = .idle
                    errorMessage = nil
                }
            }
        } catch {
            errorMessage = "Fotoğraf yüklenemedi."
        }
    }

    // MARK: - Remove image

    func removeImage() {
        selectedItem = nil
        imageData = nil
    }

    // MARK: - Submit

    func submit() async {
        guard canSubmit else { return }
        uploadState = .uploading
        errorMessage = nil

        do {
            // In production: upload imageData to server, get back URL
            // For mock: simulate with a fake URL
            let fakeURL = URL(string: "https://example.com/uploads/\(assignment.id)-\(UUID().uuidString).jpg")!
            _ = try await assignmentService.uploadAssignment(id: assignment.id, fileURL: fakeURL)
            uploadState = .success
        } catch {
            uploadState = .error
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Upload State

    enum UploadState: Equatable {
        case idle
        case uploading
        case success
        case error
    }
}
