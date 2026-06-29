//
//  ScannerScreen.swift
//  Obsidium
//
//  Full-screen camera scanner. The camera fills the entire screen; controls float
//  above it. A bottom floating button opens Photos so a QR can be selected from
//  the album and decoded with Vision.
//

import SwiftUI
import PhotosUI
import Vision
import AVFoundation

struct ScannerScreen: View {
    @Environment(VaultStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var permission: CameraPermission = .undetermined
    @State private var errorMessage: String?

    @State private var isShowingPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isProcessingPhoto = false

    var body: some View {
        ZStack {
            content
                .ignoresSafeArea()

            VStack {
                topControls
                Spacer()
                albumButton
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(.black)
        .photosPicker(
            isPresented: $isShowingPhotoPicker,
            selection: $photoPickerItem,
            matching: .images,
            preferredItemEncoding: .automatic
        )
        .onChange(of: photoPickerItem) { _, item in
            guard let item else { return }
            Task { await processPhoto(item) }
        }
        .alert("Couldn't Add Token", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .task { await requestCameraAccess() }
    }

    @ViewBuilder
    private var content: some View {
        switch permission {
        case .undetermined:
            Color.black.overlay(ProgressView().tint(.white))
        case .denied:
            Color.black.overlay(permissionDeniedView)
        case .authorized:
            QRScannerView(onFound: handleScan, onError: { errorMessage = "The camera is unavailable on this device." })
        }
    }

    private var topControls: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.35), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 1))
            }
            .accessibilityLabel("Close scanner")

            Spacer()
        }
    }

    private var albumButton: some View {
        Button {
            isShowingPhotoPicker = true
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                if isProcessingPhoto {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.body.weight(.semibold))
                }
                Text(isProcessingPhoto ? "Scanning Photo…" : "Choose from Album")
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(.black.opacity(0.42), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
        }
        .disabled(isProcessingPhoto)
        .accessibilityLabel("Choose QR code from album")
    }

    private var permissionDeniedView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white)
            VStack(spacing: Theme.Spacing.sm) {
                Text("Camera Access Needed")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Enable camera access in Settings to scan QR codes.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
        }
        .padding(Theme.Spacing.xl)
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func handleScan(_ value: String) {
        do {
            let account = try OTPAuthParser.parse(value)
            store.add(account)
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "That QR code couldn't be read."
        }
    }

    private func processPhoto(_ item: PhotosPickerItem) async {
        isProcessingPhoto = true
        defer {
            isShowingPhotoPicker = false
            photoPickerItem = nil
            isProcessingPhoto = false
        }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            await MainActor.run { errorMessage = "Couldn't read that photo." }
            return
        }

        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            if let result = request.results?.first,
               let payload = result.payloadStringValue {
                await MainActor.run { handleScan(payload) }
            } else {
                await MainActor.run { errorMessage = "No QR code found in that photo." }
            }
        } catch {
            await MainActor.run { errorMessage = "Couldn't detect a QR code in that photo." }
        }
    }

    private func requestCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permission = .authorized
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permission = granted ? .authorized : .denied
        default:
            permission = .denied
        }
    }
}

private enum CameraPermission {
    case undetermined, authorized, denied
}
