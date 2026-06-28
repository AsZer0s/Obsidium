//
//  ScannerScreen.swift
//  Obsidium
//
//  Hosts the camera scanner in a sheet, parses the scanned otpauth:// URI,
//  adds the account to the store, and handles permission / error states.
//  Also provides a Photos picker to scan a QR from a saved image (Vision
//  framework for static-image QR detection).
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
        NavigationStack {
            VStack(spacing: 0) {
                content
                Divider().overlay(Theme.cardStroke)
                Button {
                    isShowingPhotoPicker = true
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Scan from Album")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.accent)
                    .padding(.vertical, Theme.Spacing.lg)
                }
                .disabled(isProcessingPhoto)
            }
            .navigationTitle("Scan Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $isShowingPhotoPicker) {
                PhotosPicker(
                    selection: $photoPickerItem,
                    matching: .images,
                    preferredItemEncoding: .automatic
                ) {
                    Text("Cancel")
                }
            }
            .onChange(of: photoPickerItem) { _, item in
                guard let item else { return }
                Task {
                    await processPhoto(item)
                }
            }
            .alert("Couldn't Add Token", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .task { await requestCameraAccess() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch permission {
        case .undetermined:
            Color.black.overlay(ProgressView())
        case .denied:
            ZStack {
                Color.black
                ContentUnavailableView {
                    Label("Camera Access Needed", systemImage: "camera.fill")
                } description: {
                    Text("Enable camera access in Settings to scan QR codes.")
                } actions: {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                }
            }
        case .authorized:
            QRScannerView(onFound: handleScan, onError: { errorMessage = "The camera is unavailable on this device." })
                .ignoresSafeArea(edges: [.bottom, .horizontal])
        }
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
        request.symbologies = [.QR]

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
