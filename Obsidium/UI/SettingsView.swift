//
//  SettingsView.swift
//  Obsidium
//
//  Security toggles (Face ID app lock, Face ID for sensitive actions) and
//  encrypted backup export / import. Backups are password-encrypted with
//  PBKDF2 + AES-GCM (see BackupCrypto).
//

import SwiftUI
import UniformTypeIdentifiers

/// Wraps the encrypted backup bytes so SwiftUI's `.fileExporter` can write them.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private enum PasswordFlow: Identifiable {
    case export, restore
    var id: Int { self == .export ? 0 : 1 }
}

struct SettingsView: View {
    @Environment(VaultStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @AppStorage("requireBiometricsForSensitiveActions") private var requireBiometrics = false

    @State private var exportDocument = BackupDocument(data: Data())
    @State private var isExporting = false
    @State private var isImporting = false

    @State private var passwordFlow: PasswordFlow?
    @State private var submittedPassword: String?
    @State private var pendingImportData: Data?

    @State private var resultMessage: String?

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                securitySection
                organizeSection
                backupSection
                aboutSection
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
                contentType: .data,
                defaultFilename: "obsidium-backup.obsidium"
            ) { result in
                if case .failure = result { resultMessage = "Export failed." }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.data]) { result in
                handleFilePicked(result)
            }
            .sheet(item: $passwordFlow, onDismiss: runPasswordFlow) { flow in
                PasswordPromptView(
                    title: flow == .export ? "Encrypt Backup" : "Restore Backup",
                    actionLabel: flow == .export ? "Export" : "Restore",
                    requiresConfirmation: flow == .export
                ) { password in
                    submittedPassword = password
                }
            }
            .alert("Backup", isPresented: resultBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resultMessage ?? "")
            }
            .onChange(of: appLockEnabled) { _, enabled in
                // Prompt right away so enabling gives immediate feedback and
                // confirms the device can authenticate; revert on failure.
                guard enabled else { return }
                Task {
                    let ok = await Biometrics.authenticate(reason: "Confirm to turn on Face ID lock")
                    if !ok { await MainActor.run { appLockEnabled = false } }
                }
            }
        }
    }

    // MARK: Sections

    private var securitySection: some View {
        Section {
            Toggle("Lock with Face ID", isOn: $appLockEnabled)
                .disabled(!Biometrics.isAvailable)
            Toggle("Face ID for delete & export", isOn: $requireBiometrics)
                .disabled(!Biometrics.isAvailable)
        } header: {
            Text("Security")
        } footer: {
            Text(Biometrics.isAvailable
                 ? "Require Face ID to open Obsidium, and before deleting a token or exporting a backup."
                 : "Biometric authentication isn't available on this device.")
        }
    }

    private var organizeSection: some View {
        Section {
            if store.accounts.count > 1 {
                NavigationLink {
                    ReorderTokensView()
                } label: {
                    Label("Reorder Tokens", systemImage: "arrow.up.arrow.down")
                }
            }
        } header: {
            Text("Organize")
        } footer: {
            Text(store.accounts.count > 1
                 ? "Drag tokens to change the order they appear in the deck."
                 : "Add a second token to start arranging them.")
        }
    }

    private var backupSection: some View {
        Section {
            Button {
                startExport()
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
            Text("Backups are encrypted with a password you choose (PBKDF2 + AES-GCM). Keep the password safe — it can't be recovered.")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: appVersion)
        } header: {
            Text("About")
        } footer: {
            Text("Obsidium keeps everything on this device. No cloud, no accounts, no sync.")
        }
    }

    // MARK: Flows

    private var resultBinding: Binding<Bool> {
        Binding(get: { resultMessage != nil }, set: { if !$0 { resultMessage = nil } })
    }

    private func startExport() {
        let present = { passwordFlow = .export }
        guard requireBiometrics else { present(); return }
        Task {
            if await Biometrics.authenticate(reason: "Authenticate to export your backup") {
                await MainActor.run(body: present)
            }
        }
    }

    private func handleFilePicked(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else {
            resultMessage = "Couldn't read that file."
            return
        }
        pendingImportData = data
        passwordFlow = .restore   // ask for the password, then decrypt
    }

    /// Runs after the password sheet fully dismisses, so presenting the file
    /// exporter / alert next doesn't collide with the dismissing sheet.
    private func runPasswordFlow() {
        guard let password = submittedPassword else {
            pendingImportData = nil   // cancelled
            return
        }
        submittedPassword = nil

        if let data = pendingImportData {
            pendingImportData = nil
            restore(from: data, password: password)
        } else {
            export(with: password)
        }
    }

    private func export(with password: String) {
        guard let plaintext = store.exportData() else {
            resultMessage = "Nothing to export."
            return
        }
        do {
            exportDocument = BackupDocument(data: try BackupCrypto.encrypt(plaintext, password: password))
            isExporting = true
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't create the backup."
        }
    }

    private func restore(from data: Data, password: String) {
        do {
            let plaintext = try BackupCrypto.decrypt(data, password: password)
            if let added = store.merge(from: plaintext) {
                resultMessage = added == 0 ? "Backup restored. No new tokens." : "Imported \(added) new token(s)."
            } else {
                resultMessage = "That file isn't a valid Obsidium backup."
            }
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't restore the backup."
        }
    }
}

/// A always-editable list for drag-to-reorder the deck. Changes persist live.
private struct ReorderTokensView: View {
    @Environment(VaultStore.self) private var store

    var body: some View {
        List {
            ForEach(store.accounts) { account in
                row(for: account)
            }
            .onMove { source, destination in
                store.move(from: source, to: destination)
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Reorder")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(for account: Account) -> some View {
        let icon = account.iconID.flatMap { BrandIcon.find(id: $0) }
            ?? BrandIcon.autodetect(for: account.issuer)
            ?? .default
        let hasLabel = !account.label.isEmpty && account.displayTitle != account.label

        return HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(icon.tint ?? Theme.accent)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(account.displayTitle)
                    .font(.body)
                    .lineLimit(1)
                if hasLabel {
                    Text(account.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }
}
