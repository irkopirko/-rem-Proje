import AVFoundation
import SwiftUI

struct QRScannerFlowView: View {
    @Bindable var viewModel: QRScannerViewModel
    var onResolvedLesson: (Lesson) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var manualCode = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                header

                scannerSection
                    .animation(.easeInOut(duration: 0.25), value: viewModel.cameraPermissionState)

                statusSection

                manualEntrySection

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .background(Color.inkBackground)
            .navigationTitle("QR Tarayıcı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                }
            }
            .task {
                await viewModel.requestCameraAccess()
            }
            .onChange(of: viewModel.resolvedLesson) { _, lesson in
                guard let lesson else { return }
                onResolvedLesson(lesson)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Ders Kilidini Aç")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.inkTextPrimary)

            Text("QR kodu taratın ve ilgili derse hızlıca gidin.")
                .font(.subheadline)
                .foregroundStyle(Color.inkTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private var scannerSection: some View {
        if viewModel.cameraPermissionState == .granted {
            QRCodeScannerView(isRunning: viewModel.isScannerActive) { payload in
                Task { await viewModel.handleScanned(payload) }
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.inkDivider, lineWidth: 0.8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.inkBlack.opacity(0.1), lineWidth: 8)
            )
        } else {
            cameraPermissionCard
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var statusSection: some View {
        VStack(spacing: 12) {
            if viewModel.status == .processing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.9)
                    Text("Kod doğrulanıyor...")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.inkTextSecondary)
                }
            }

            if case .invalid(let message) = viewModel.status {
                statusBanner(message: message, color: Color.inkError)
                retryButton
            }

            if case .accessDenied(let message) = viewModel.status {
                statusBanner(message: message, color: Color.inkWarning)
                retryButton
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.status)
    }

    private var retryButton: some View {
        Button("Tekrar Dene") {
            viewModel.reset()
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.inkBlack)
    }

    private func statusBanner(message: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.inkTextPrimary)
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var manualEntrySection: some View {
        VStack(spacing: 12) {
            TextField("Kod girin (ör. INKA:lesson-1-1)", text: $manualCode)
                .textInputAutocapitalization(.never)
                .padding(12)
                .background(Color.inkSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.inkDivider, lineWidth: 0.6)
                )

            Button {
                Task { await viewModel.handleScanned(manualCode) }
            } label: {
                Text("Kodu Doğrula")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.inkBlack)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(manualCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var cameraPermissionCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.inkTextSecondary)

            Text("Kamera erişimi gerekli")
                .font(.headline)
                .foregroundStyle(Color.inkTextPrimary)

            Text("QR kodunu taramak için kamera izni verin.")
                .font(.subheadline)
                .foregroundStyle(Color.inkTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.inkDivider, lineWidth: 0.8)
        )
    }
}

private struct QRCodeScannerView: UIViewRepresentable {
    var isRunning: Bool
    var onCode: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCode: onCode)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let session = context.coordinator.session
        context.coordinator.configureSession()

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer

        if isRunning {
            context.coordinator.startSession()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
        if isRunning {
            context.coordinator.startSession()
        } else {
            context.coordinator.stopSession()
        }
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let session = AVCaptureSession()
        private let onCode: (String) -> Void
        private var isConfigured = false
        private var isRunning = false
        var previewLayer: AVCaptureVideoPreviewLayer?

        init(onCode: @escaping (String) -> Void) {
            self.onCode = onCode
        }

        func configureSession() {
            guard !isConfigured else { return }
            session.beginConfiguration()

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else {
                session.commitConfiguration()
                return
            }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                return
            }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]

            session.commitConfiguration()
            isConfigured = true
        }

        func startSession() {
            guard !isRunning else { return }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
                DispatchQueue.main.async {
                    self?.isRunning = true
                }
            }
        }

        func stopSession() {
            guard isRunning else { return }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
                DispatchQueue.main.async {
                    self?.isRunning = false
                }
            }
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  object.type == .qr,
                  let value = object.stringValue else { return }
            onCode(value)
        }
    }
}

#Preview {
    QRScannerFlowView(viewModel: QRScannerViewModel(qrService: MockQRService())) { lesson in
        print(lesson.id)
    }
}
