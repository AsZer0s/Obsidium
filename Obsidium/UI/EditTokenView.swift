//
//  EditTokenView.swift
//  Obsidium
//
//  A modern sheet to edit a token's name, account name, and
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
                    previewCard
                    iconSection
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

    // MARK: Preview Card

    private var previewCard: some View {
        VStack(spacing: Theme.Spacing.lg) {
            HStack(spacing: Theme.Spacing.lg) {
                let icon = selectedBrandIcon
                Image(systemName: icon.symbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(icon.tint ?? Theme.accent)
                    .frame(width: 72, height: 72)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).stroke(Theme.cardStroke, lineWidth: 1))

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(issuer.isEmpty ? "Issuer" : issuer)
                        .font(Theme.Typography.issuer)
                        .foregroundStyle(issuer.isEmpty ? .tertiary : .primary)
                    Text(label.isEmpty ? "Account" : label)
                        .font(Theme.Typography.label)
                        .foregroundStyle(label.isEmpty ? .tertiary : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).stroke(Theme.cardStroke, lineWidth: 1))
    }

    private var selectedBrandIcon: BrandIcon {
        selectedIconID.flatMap { BrandIcon.find(id: $0) } ?? .default
    }

    // MARK: Icon Section

    private var iconSection: some View {
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
        VStack(spacing: 0) {
            fieldRow(
                title: "Name",
                placeholder: "Issuer (e.g. GitHub)",
                text: $issuer,
                icon: "building.2.fill"
            )

            Divider()
                .overlay(Color.white.opacity(0.1))
                .padding(.leading, 52)

            fieldRow(
                title: "Account",
                placeholder: "Account name (e.g. johndoe)",
                text: $label,
                icon: "person.fill"
            )

            Divider()
                .overlay(Color.white.opacity(0.1))
                .padding(.leading, 52)

            secretFieldRow
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).stroke(Theme.cardStroke, lineWidth: 1))
    }

    private func fieldRow(title: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(Theme.Spacing.lg)
    }

    private var secretFieldRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "key.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(secretIsValid ? Theme.accent : Theme.warning)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("Secret")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Base32 secret", text: $secret, axis: .vertical)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }

            if !secret.isEmpty {
                Image(systemName: secretIsValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(secretIsValid ? .green : Theme.warning)
            }
        }
        .padding(Theme.Spacing.lg)
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
