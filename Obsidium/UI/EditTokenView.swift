//
//  EditTokenView.swift
//  Obsidium
//
//  A simple sheet to edit a token's name (issuer), account name (label), and
//  TOTP key (Base32 secret). The id, algorithm, digits, and period are kept as
//  they were. Save is disabled until the key is valid Base32.
//

import SwiftUI

struct EditTokenView: View {
    @Environment(\.dismiss) private var dismiss

    private let original: Account
    private let onSave: (Account) -> Void

    @State private var issuer: String
    @State private var label: String
    @State private var secret: String

    init(account: Account, onSave: @escaping (Account) -> Void) {
        self.original = account
        self.onSave = onSave
        _issuer = State(initialValue: account.issuer)
        _label = State(initialValue: account.label)
        _secret = State(initialValue: account.secret)
    }

    private var normalizedSecret: String {
        secret.replacingOccurrences(of: " ", with: "").uppercased()
    }

    private var secretIsValid: Bool {
        if let bytes = Base32.decode(normalizedSecret), !bytes.isEmpty { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Issuer", text: $issuer)
                        .autocorrectionDisabled()
                }
                Section("Account") {
                    TextField("Account name", text: $label)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    TextField("Base32 secret", text: $secret, axis: .vertical)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                } header: {
                    Text("TOTP Key")
                } footer: {
                    if !secretIsValid {
                        Text("Not a valid Base32 key.")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Token")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!secretIsValid)
                }
            }
        }
    }

    private func save() {
        var updated = original
        updated.issuer = issuer.trimmingCharacters(in: .whitespaces)
        updated.label = label.trimmingCharacters(in: .whitespaces)
        updated.secret = normalizedSecret
        onSave(updated)
        dismiss()
    }
}
