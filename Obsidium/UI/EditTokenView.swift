//
//  EditTokenView.swift
//  Obsidium
//
//  Edit a token as a secure credential pass: a live Wallet-style preview,
//  concise identity fields, a distinct secret vault row, and a FontAwesome
//  brand mark picker.
//

import SwiftUI
import UIKit

struct EditTokenView: View {
    @Environment(VaultStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let account: Account
    private let onSave: ((Account) -> Void)?

    @State private var issuer: String
    @State private var label: String
    @State private var secret: String
    @State private var selectedIconID: String?
    @State private var isShowingIconPicker = false
    @State private var iconSearchQuery = ""

    init(account: Account, onSave: ((Account) -> Void)? = nil) {
        self.account = account
        self.onSave = onSave
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

    private var selectedBrandIcon: BrandIcon {
        selectedIconID.flatMap { BrandIcon.find(id: $0) } ?? .default
    }

    private var filteredIcons: [BrandIcon] {
        if iconSearchQuery.isEmpty { return BrandIcon.library }
        let query = iconSearchQuery.lowercased()
        return BrandIcon.library.filter { icon in
            icon.name.lowercased().contains(query) ||
            icon.id.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                editBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        previewPass
                        identityPanel
                        secretPanel
                        brandPanel
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
                .scrollIndicators(.hidden)
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
            .sheet(isPresented: $isShowingIconPicker) {
                iconPickerSheet
            }
        }
    }

    // MARK: - Preview

    private var previewPass: some View {
        let icon = selectedBrandIcon
        return ZStack(alignment: .bottomLeading) {
            passGradient(for: icon)

            FontAwesomeIconView(icon: icon, size: 170)
                .foregroundStyle(.white.opacity(0.09))
                .rotationEffect(.degrees(-13))
                .offset(x: 84, y: 36)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .allowsHitTesting(false)

            LinearGradient(
                colors: [.white.opacity(0.18), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .blendMode(.overlay)

            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                HStack(alignment: .center) {
                    brandSeal(icon)
                    Spacer()
                    Text("TOTP")
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.72))
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(.white.opacity(0.13), in: Capsule())
                }

                Spacer(minLength: Theme.Spacing.md)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(issuer.isEmpty ? "Service name" : issuer)
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundStyle(issuer.isEmpty ? .white.opacity(0.55) : .white)
                        .lineLimit(1)
                    Text(label.isEmpty ? "Account label" : label)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(label.isEmpty ? .white.opacity(0.42) : .white.opacity(0.72))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: (icon.tint ?? Theme.accent).opacity(0.28), radius: 22, y: 12)
        .shadow(color: .black.opacity(0.38), radius: 12, y: 6)
    }

    private func brandSeal(_ icon: BrandIcon) -> some View {
        FontAwesomeIconView(icon: icon, size: 24)
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            )
    }

    // MARK: - Panels

    private var identityPanel: some View {
        editorPanel(title: "Identity", subtitle: "What this pass says on the deck.") {
            VStack(spacing: Theme.Spacing.md) {
                editorField(
                    title: "Name",
                    placeholder: "GitHub, Apple ID, Cloudflare…",
                    text: $issuer,
                    systemImage: "rectangle.stack.fill"
                )
                Divider().overlay(Color.white.opacity(0.08))
                editorField(
                    title: "Account",
                    placeholder: "you@example.com",
                    text: $label,
                    systemImage: "person.text.rectangle.fill"
                )
            }
        }
    }

    private var secretPanel: some View {
        editorPanel(title: "Secret", subtitle: "Base32 seed used to generate one-time codes.") {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                Image(systemName: "key.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secretIsValid ? Theme.accent : Theme.warning)
                    .frame(width: 30, height: 34)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    TextField("JBSWY3DPEHPK3PXP", text: $secret, axis: .vertical)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .lineLimit(2...4)

                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: secretIsValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        Text(secretIsValid ? "Valid Base32 secret" : "Enter a valid Base32 secret")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(secretIsValid ? Theme.accent : Theme.warning)
                }
            }
        }
    }

    private var brandPanel: some View {
        editorPanel(title: "Brand mark", subtitle: "Used as the card watermark and management icon.") {
            Button {
                isShowingIconPicker = true
            } label: {
                let icon = selectedBrandIcon
                HStack(spacing: Theme.Spacing.md) {
                    FontAwesomeIconView(icon: icon, size: 25)
                        .foregroundStyle(icon.tint ?? Theme.accent)
                        .frame(width: 54, height: 54)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Theme.cardStroke, lineWidth: 1)
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(icon.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Choose from FontAwesome")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func editorPanel<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .padding(Theme.Spacing.lg)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
    }

    private func editorField(title: String, placeholder: String, text: Binding<String>, systemImage: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
    }

    // MARK: - Icon Picker

    private var iconPickerSheet: some View {
        NavigationStack {
            ZStack {
                editBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    searchField
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: Theme.Spacing.md)], spacing: Theme.Spacing.md) {
                            Button {
                                selectedIconID = nil
                                isShowingIconPicker = false
                            } label: {
                                iconGridItem(nil)
                            }
                            .buttonStyle(.plain)

                            ForEach(filteredIcons, id: \.id) { icon in
                                Button {
                                    selectedIconID = icon.id
                                    isShowingIconPicker = false
                                } label: {
                                    iconGridItem(icon)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xxl)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Choose Mark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isShowingIconPicker = false }
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search FontAwesome marks", text: $iconSearchQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
    }

    private func iconGridItem(_ icon: BrandIcon?) -> some View {
        let displayIcon = icon ?? .default
        let isSelected = icon == nil ? selectedIconID == nil : selectedIconID == displayIcon.id

        return VStack(spacing: Theme.Spacing.sm) {
            FontAwesomeIconView(icon: displayIcon, size: 30)
                .foregroundStyle(displayIcon.tint ?? Theme.accent)
                .frame(width: 66, height: 66)
                .background(.white.opacity(isSelected ? 0.16 : 0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? Theme.accent.opacity(0.95) : Theme.cardStroke, lineWidth: isSelected ? 2 : 1)
                )

            Text(displayIcon.name)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Styling

    private var editBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.045, green: 0.047, blue: 0.062),
                Color(red: 0.018, green: 0.020, blue: 0.030),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func passGradient(for icon: BrandIcon) -> some View {
        let tint = brandTint(for: icon)
        let light = tint.brightness > 0.62
        let top = tint.mixed(with: .black, amount: light ? 0.50 : 0.26)
        let bottom = tint.mixed(with: .black, amount: light ? 0.82 : 0.66)
        return LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func brandTint(for icon: BrandIcon) -> Color {
        let tint = icon.tint ?? Theme.accent
        return tint.brightness < 0.10 ? Color(white: 0.22) : tint
    }

    private func save() {
        var updated = account
        updated.issuer = issuer.trimmingCharacters(in: .whitespaces)
        updated.label = label.trimmingCharacters(in: .whitespaces)
        updated.secret = normalizedSecret
        updated.iconID = selectedIconID
        if let onSave = onSave {
            onSave(updated)
        } else {
            store.update(updated)
        }
        dismiss()
    }
}

private extension Color {
    var brightness: CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b
    }

    func mixed(with other: Color, amount: CGFloat) -> Color {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = max(0, min(1, amount))
        return Color(
            red: Double(r1 + (r2 - r1) * t),
            green: Double(g1 + (g2 - g1) * t),
            blue: Double(b1 + (b2 - b1) * t)
        )
    }
}
