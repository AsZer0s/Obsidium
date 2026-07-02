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
    @State private var isConfirmingRestore = false

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
            .alert("Restore Backup?", isPresented: $isConfirmingRestore) {
                Button("Cancel", role: .cancel) {
                    pendingImportData = nil
                }
                Button("Continue") {
                    passwordFlow = .restore
                }
            } message: {
                Text("Obsidium will decrypt this file and merge it into your current vault. Existing tokens are not erased; matching backup tokens are updated and new tokens are added.")
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
            if store.accounts.isEmpty {
                Label("No Tokens", systemImage: "list.bullet.rectangle")
                    .foregroundStyle(.secondary)
            } else {
                NavigationLink {
                    ManageTokensView()
                } label: {
                    Label("Manage Tokens", systemImage: "list.bullet.rectangle")
                }
            }
        } header: {
            Text("Tokens")
        } footer: {
            Text(store.accounts.isEmpty
                 ? "Add a token to manage it here."
                 : "Tap to edit, swipe for actions, or tap Edit to reorder tokens.")
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
                Label("Restore Backup", systemImage: "square.and.arrow.down")
            }
        } header: {
            Text("Backup")
        } footer: {
            Text("Backups are encrypted with a password you choose (PBKDF2 + AES-GCM). Restoring merges with your current tokens and does not erase the vault.")
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
        isConfirmingRestore = true
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
                resultMessage = added == 0
                    ? "Backup restored and merged. No new tokens were added; existing tokens were left in place or updated."
                    : "Backup restored and merged. Imported \(added) new token(s); existing tokens were left in place."
            } else {
                resultMessage = "That file isn't a valid Obsidium backup."
            }
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't restore the backup."
        }
    }
}

/// A system List for token management: tap to edit, swipe for edit/delete,
/// and use Edit mode's native reorder handles to rearrange the deck.
private struct ManageTokensView: View {
    @Environment(VaultStore.self) private var store
    @AppStorage("requireBiometricsForSensitiveActions") private var requireBiometrics = false
    @State private var editingAccount: Account?

    var body: some View {
        List {
            ForEach(store.accounts) { account in
                row(for: account)
                    .contentShape(Rectangle())
                    .onTapGesture { editingAccount = account }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            editingAccount = account
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Theme.accent)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteGated(account)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onMove { source, destination in
                store.move(from: source, to: destination)
            }
        }
        .navigationTitle("Manage Tokens")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(item: $editingAccount) { account in
            EditTokenView(account: account) { store.update($0) }
        }
    }

    private func row(for account: Account) -> some View {
        let icon = account.iconID.flatMap { BrandIcon.find(id: $0) }
            ?? BrandIcon.autodetect(for: account.issuer)
            ?? .default
        let hasLabel = !account.label.isEmpty && account.displayTitle != account.label

        return HStack(spacing: Theme.Spacing.md) {
            FontAwesomeIconView(icon: icon, size: 18)
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

    private func deleteGated(_ account: Account) {
        guard requireBiometrics else {
            store.delete(account)
            return
        }
        Task {
            if await Biometrics.authenticate(reason: "Authenticate to delete this token") {
                await MainActor.run { store.delete(account) }
            }
        }
    }
}
