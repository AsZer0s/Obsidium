//
//  QRScannerView.swift
//  Obsidium
//
//  A thin SwiftUI wrapper over an AVCaptureSession that scans QR codes and
//  reports the first decoded string. Camera only — not available in the
//  Simulator (run on a device to scan).
//

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    /// Called once with the first decoded QR payload.
    let onFound: (String) -> Void
    /// Called if the camera is unavailable or permission is denied.
    let onError: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFound: onFound)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        controller.onError = onError
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let onFound: (String) -> Void
        private var hasReported = false

        init(onFound: @escaping (String) -> Void) {
            self.onFound = onFound
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            // Report only the first valid QR payload, then stop.
            guard !hasReported,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  object.type == .qr,
                  let value = object.stringValue else { return }
            hasReported = true
            DispatchQueue.main.async { [weak self] in
                self?.onFound(value)
            }
        }
    }
}

// MARK: - Capture controller

final class ScannerViewController: UIViewController {
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?
    var onError: (() -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            onError?()
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            onError?()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(delegate, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.layer.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startRunningIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            // Stopping the session can block; do it off the main thread.
            Task.detached { [session] in session.stopRunning() }
        }
    }

    private func startRunningIfNeeded() {
        guard !session.isRunning, !session.inputs.isEmpty else { return }
        // startRunning() is blocking; keep it off the main thread.
        Task.detached { [session] in session.startRunning() }
    }
}
