//
//  ScannerScreen.swift
//  Obsidium
//
//  Hosts the camera scanner in a sheet, parses the scanned otpauth:// URI,
//  adds the account to the store, and handles permission / error states.
//

import SwiftUI
import AVFoundation

struct ScannerScreen: View {
    @Environment(VaultStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var permission: CameraPermission = .undetermined
    @State private var errorMessage: String?

    private enum CameraPermission {
        case undetermined, authorized, denied
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Scan Code")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .alert("Couldn't Add Token", isPresented: errorBinding) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage ?? "")
                }
        }
        .task { await requestCameraAccess() }
    }

    @ViewBuilder
    private var content: some View {
        switch permission {
        case .undetermined:
            ProgressView()
        case .denied:
            deniedState
        case .authorized:
            QRScannerView(
                onFound: handleScan,
                onError: { errorMessage = "The camera is unavailable on this device." }
            )
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                Text("Point the camera at a 2FA QR code")
                    .font(.callout)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 32)
            }
        }
    }

    private var deniedState: some View {
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
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func handleScan(_ value: String) {
        do {
            let account = try OTPAuthParser.parse(value)
            store.add(account)
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "That QR code couldn't be read."
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
