//
//  EditTokenView.swift
//  Obsidium
//
//  A simple sheet to edit a token's name, account name, and
//  TOTP key (Base32 secret). Also lets you select a brand icon
//  from a picker grid.
//

import SwiftUI

struct EditTokenView: View {
    @Environment(VaultStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let account: Account
    @State private var issuer: String
    @State private var label: String
    @State private var secret: String
    @State private var selectedIconID: String?

    init(account: Account, onSave: ((Account) -> Void)? = nil) {
        self.account = account
        _issuer = State(initialValue: account.issuer)
        _label = State(initialValue: account.label)
        _secret = State(initialValue: account.secret)
        _selectedIconID = State(initialValue: account.iconID)
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
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    iconPickerSection
                    fieldsSection
                }
                .padding(Theme.Spacing.lg)
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

    // MARK: Icon Picker

    private var iconPickerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Icon")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    iconCell(nil)
                    ForEach(BrandIcon.library, id: \.id) { icon in
                        iconCell(icon)
                    }
                }
            }
        }
    }

    private func iconCell(_ icon: BrandIcon?) -> some View {
        let isSelected = selectedIconID == icon?.id
        let displayIcon = icon ?? .default

        return Button {
            withAnimation(.easeInOut) {
                selectedIconID = displayIcon.id
            }
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: displayIcon.symbol)
                    .font(.title2)
                    .foregroundStyle(displayIcon.tint ?? Theme.accent)
                    .frame(width: 56, height: 56)
                    .background(Color.gray.opacity(isSelected ? 0.3 : 0.15))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    .overlay(isSelected ?
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(Theme.accent, lineWidth: 2) : nil
                    )

                Text(displayIcon.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 68)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Fields

    private var fieldsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            LabeledContent("Name") {
                TextField("Issuer", text: $issuer)
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("Account") {
                TextField("Account name", text: $label)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            LabeledContent("Secret") {
                TextField("Base32 secret", text: $secret, axis: .vertical)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).stroke(Theme.cardStroke, lineWidth: 1))
    }

    private func save() {
        var updated = account
        updated.issuer = issuer.trimmingCharacters(in: .whitespaces)
        updated.label = label.trimmingCharacters(in: .whitespaces)
        updated.secret = normalizedSecret
        updated.iconID = selectedIconID
        store.update(updated)
        dismiss()
    }
}
