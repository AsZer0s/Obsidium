//
//  SettingsView.swift
//  Obsidium
//
//  Backup export / import / restore and a Face ID toggle that gates the
//  sensitive actions (delete & export). Kept to a single Form.
//

import SwiftUI
import UniformTypeIdentifiers

/// Wraps the exported JSON so SwiftUI's `.fileExporter` can write it.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct SettingsView: View {
    @Environment(VaultStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @AppStorage("requireBiometricsForSensitiveActions")
    private var requireBiometrics = false

    @State private var exportDocument = BackupDocument(data: Data())
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var resultMessage: String?

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Require Face ID", isOn: $requireBiometrics)
                        .disabled(!Biometrics.isAvailable)
                } header: {
                    Text("Security")
                } footer: {
                    Text(Biometrics.isAvailable
                         ? "Ask for Face ID before deleting a token or exporting a backup."
                         : "Biometric authentication isn't available on this device.")
                }

                Section {
                    Button {
                        exportTapped()
                    } label: {
                        Label("Export Backup", systemImage: "square.and.arrow.up")
                    }
                    .disabled(store.accounts.isEmpty)

                    Button {
                        isImporting = true
                    } label: {
                        Label("Import / Restore", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Backup")
                } footer: {
                    Text("The backup file contains your secret keys in plain text. Store it somewhere safe and delete it when you're done.")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                } header: {
                    Text("About")
                } footer: {
                    Text("Obsidium keeps everything on this device. No cloud, no accounts, no sync.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "obsidium-backup"
            ) { result in
                if case .failure = result { resultMessage = "Export failed." }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json]
            ) { result in
                handleImport(result)
            }
            .alert("Backup", isPresented: resultBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resultMessage ?? "")
            }
        }
    }

    private var resultBinding: Binding<Bool> {
        Binding(get: { resultMessage != nil }, set: { if !$0 { resultMessage = nil } })
    }

    private func exportTapped() {
        let action = {
            guard let data = store.exportData() else {
                resultMessage = "Nothing to export."
                return
            }
            exportDocument = BackupDocument(data: data)
            isExporting = true
        }
        if requireBiometrics {
            Task {
                if await Biometrics.authenticate(reason: "Authenticate to export your backup") {
                    await MainActor.run(body: action)
                }
            }
        } else {
            action()
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else {
                resultMessage = "Couldn't read that file."
                return
            }
            if let added = store.merge(from: data) {
                resultMessage = added == 0 ? "Backup restored. No new tokens." : "Imported \(added) new token(s)."
            } else {
                resultMessage = "That file isn't a valid Obsidium backup."
            }
        case .failure:
            break   // user cancelled
        }
    }
}
