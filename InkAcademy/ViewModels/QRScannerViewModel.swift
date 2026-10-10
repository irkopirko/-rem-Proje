import AVFoundation
import Foundation

@Observable
final class QRScannerViewModel {
    enum CameraPermissionState {
        case unknown
        case granted
        case denied
    }

    enum ScanStatus: Equatable {
        case idle
        case processing
        case success
        case invalid(String)
        case accessDenied(String)
    }

    var cameraPermissionState: CameraPermissionState = .unknown
    var status: ScanStatus = .idle
    var resolvedLesson: Lesson?
    var resolvedContent: QRResolution?
    var isProcessing = false

    private let qrService: QRServiceProtocol

    init(qrService: QRServiceProtocol) {
        self.qrService = qrService
    }

    var isScannerActive: Bool {
        cameraPermissionState == .granted && status == .idle
    }

    func requestCameraAccess() async {
        let current = AVCaptureDevice.authorizationStatus(for: .video)
        switch current {
        case .authorized:
            cameraPermissionState = .granted
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraPermissionState = granted ? .granted : .denied
        default:
            cameraPermissionState = .denied
        }
    }

    func handleScanned(_ payload: String) async {
        guard status == .idle, !isProcessing else { return }
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            status = .invalid("Geçersiz QR kodu. Lütfen tekrar deneyin.")
            return
        }

        isProcessing = true
        status = .processing

        do {
            let result = try await qrService.resolveContent(qrPayload: trimmed)
            resolvedContent = result
            switch result {
            case .lesson(let lesson):
                resolvedLesson = lesson
                status = .success
            case .accessDenied(let message):
                status = .accessDenied(message)
            case .invalid:
                status = .invalid("Geçersiz QR kodu. Lütfen tekrar deneyin.")
            default:
                resolvedLesson = nil
                status = .success
            }
        } catch {
            status = .invalid("Kod doğrulanamadı. Lütfen tekrar deneyin.")
        }

        isProcessing = false
    }

    func reset() {
        resolvedLesson = nil
        resolvedContent = nil
        status = .idle
        isProcessing = false
    }
}
