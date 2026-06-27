//
//  PasswordPromptView.swift
//  Obsidium
//
//  Collects a password to encrypt a backup (with confirmation) or to decrypt
//  one (single field). Returns the password to the caller on submit.
//

import SwiftUI

struct PasswordPromptView: View {
    let title: String
    let actionLabel: String
    /// true → creating a backup (ask twice); false → unlocking one.
    let requiresConfirmation: Bool
    let onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmation = ""

    private var tooShort: Bool { !password.isEmpty && password.count < 6 }
    private var mismatch: Bool { requiresConfirmation && !confirmation.isEmpty && password != confirmation }
    private var isValid: Bool {
        password.count >= 6 && (!requiresConfirmation || password == confirmation)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Password", text: $password)
                    if requiresConfirmation {
                        SecureField("Confirm password", text: $confirmation)
                    }
                } footer: {
                    Text(footerText)
                        .foregroundStyle(mismatch || tooShort ? .red : .secondary)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(actionLabel) {
                        onSubmit(password)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var footerText: String {
        if mismatch { return "Passwords don't match." }
        if tooShort { return "Use at least 6 characters." }
        return requiresConfirmation
            ? "You'll need this password to restore the backup. It cannot be recovered."
            : "Enter the password used to create this backup."
    }
}
