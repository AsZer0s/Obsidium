//
//  TokenListView.swift
//  Obsidium
//
//  The app's only main screen: a dark, Apple Wallet–style stacked deck of
//  tokens with a live countdown, search, a designed empty state, Settings, an
//  Edit sheet, a copy toast, and a + button for QR/manual add. Delete is gated
//  behind Face ID when the user enables it in Settings.
//

import SwiftUI
import UIKit

struct TokenListView: View {
    @Environment(VaultStore.self) private var store
    @Environment(ToastCenter.self) private var toast
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @AppStorage("requireBiometricsForSensitiveActions")
    private var requireBiometrics = false

    @State private var isScannerPresented = false
    @State private var isManualAddPresented = false
    @State private var isAddOptionsPresented = false
    @State private var isSettingsPresented = false
    @State private var isSearchPresented = false
    @State private var editingAccount: Account?
    @State private var manualDraft = Account(issuer: "", label: "", secret: "")
    @State private var searchText = ""
    @State private var isLocked = false
    @State private var isAuthenticating = false

    private var filteredAccounts: [Account] {
        store.accounts.filter { $0.matchesSearch(searchText) }
    }

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(Theme.accent)
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .principal) {
                    Text("Obsidium")
                        .font(.headline.weight(.semibold))
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.snappy) {
                            searchText = ""
                            isSearchPresented = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .tint(Theme.accent)
                    .accessibilityLabel("Search tokens")

                    Button {
                        isAddOptionsPresented = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                    .tint(Theme.accent)
                    .accessibilityLabel("Add token")
                }
            }
            .confirmationDialog("Add Token", isPresented: $isAddOptionsPresented, titleVisibility: .visible) {
                Button("Scan QR Code") { isScannerPresented = true }
                Button("Enter Setup Key") { presentManualAdd() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Scan a QR code or manually enter the setup key from your service.")
            }
            .fullScreenCover(isPresented: $isScannerPresented) {
                ScannerScreen()
            }
            .sheet(isPresented: $isManualAddPresented) {
                EditTokenView(account: manualDraft, title: "Add Token", saveLabel: "Add") {
                    store.add($0)
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
            .sheet(item: $editingAccount) { account in
                EditTokenView(account: account) { store.update($0) }
            }
            .overlay(alignment: .bottom) {
                if let message = toast.message {
                    ToastView(text: message)
                        .padding(.bottom, Theme.Spacing.xxl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: toast.message)
        }
        .overlay {
            if isLocked {
                LockView(action: unlock)
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: isLocked)
        .onAppear {
            if appLockEnabled {
                isLocked = true
                unlock()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                if appLockEnabled && isLocked { unlock() }
            case .background:
                if appLockEnabled { isLocked = true }
            default:
                break
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isSearchPresented {
            SearchPanel(
                query: $searchText,
                accounts: filteredAccounts,
                onCancel: closeSearch
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        } else if store.accounts.isEmpty {
            EmptyStateView { isAddOptionsPresented = true }
        } else {
            // One ticking clock drives every card so codes and rings stay in sync.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                CardStack(
                    accounts: store.accounts,
                    now: context.date
                )
            }
        }
    }

    private func presentManualAdd() {
        manualDraft = Account(issuer: "", label: "", secret: "")
        isManualAddPresented = true
    }

    private func closeSearch() {
        withAnimation(.snappy) {
            isSearchPresented = false
            searchText = ""
        }
    }

    /// Delete, behind Face ID if the user enabled it.
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

    /// Prompt for biometric unlock; clears the lock on success.
    private func unlock() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        Task {
            let success = await Biometrics.authenticate(reason: "Unlock Obsidium")
            await MainActor.run {
                withAnimation(.snappy) { isLocked = !success }
                isAuthenticating = false
            }
        }
    }
}

/// Full-screen lock shown when Face ID app lock is on and the app is locked.
private struct LockView: View {
    let action: () -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Theme.accent)
                Text("Obsidium is Locked")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Button(action: action) {
                    Label("Unlock", systemImage: "faceid")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, Theme.Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .controlSize(.large)
            }
            .padding(Theme.Spacing.xl)
        }
    }
}

/// A small "Code copied" toast pinned near the bottom.
private struct ToastView: View {
    let text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.accent)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Theme.cardStroke, lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
    }
}

/// Designed empty state — a calm prompt to add the first token.
private struct EmptyStateView: View {
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().stroke(Theme.cardStroke, lineWidth: 1))
                    .frame(width: 88, height: 88)
                Image(systemName: "lock.shield")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("No Tokens Yet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Scan a 2FA QR code or enter a setup key manually.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            Button(action: onScan) {
                Label("Add Token", systemImage: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, Theme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .controlSize(.large)
            .padding(.top, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.xl)
    }
}

/// Dedicated search mode. It deliberately replaces the Wallet deck so no cards
/// are visible while searching.
private struct SearchPanel: View {
    @Binding var query: String
    let accounts: [Account]
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            searchField
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)

            if accounts.isEmpty {
                SearchEmptyState(query: query)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.md) {
                            ForEach(accounts) { account in
                                SearchResultRow(account: account, now: context.date)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xxl)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .onAppear { isFocused = true }
    }

    private var searchField: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search tokens", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear search")
            }

            Button("Cancel", action: onCancel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
    }
}

private struct SearchResultRow: View {
    let account: Account
    let now: Date

    @Environment(ToastCenter.self) private var toast

    private var code: String { TOTPGenerator.code(for: account, at: now) ?? "------" }
    private var hasCode: Bool { code != "------" }
    private var secondsRemaining: Int { TOTPGenerator.secondsRemaining(period: account.period, at: now) }
    private var hasLabel: Bool { !account.label.isEmpty && account.displayTitle != account.label }

    private var icon: BrandIcon {
        account.iconID.flatMap { BrandIcon.find(id: $0) }
            ?? BrandIcon.autodetect(for: account.issuer)
            ?? .default
    }

    var body: some View {
        Button(action: copyCode) {
            HStack(spacing: Theme.Spacing.md) {
                FontAwesomeIconView(icon: icon, size: 20)
                    .foregroundStyle(icon.tint ?? Theme.accent)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.cardStroke, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.displayTitle)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if hasLabel {
                        Text(account.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer(minLength: Theme.Spacing.md)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(hasCode ? code : "—")
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(secondsRemaining)s")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(secondsRemaining <= 5 ? Theme.warning : .secondary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!hasCode)
        .accessibilityLabel("\(account.displayTitle), \(hasLabel ? account.label : ""), code \(code)")
        .accessibilityHint("Double-tap to copy")
    }

    private func copyCode() {
        guard hasCode else { return }
        UIPasteboard.general.string = code
        Haptics.copy()
        toast.show("Code copied")
    }
}

private struct SearchEmptyState: View {
    let query: String

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.accent)
            Text("No Matching Tokens")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            Text(query.isEmpty ? "No tokens to search yet." : "No token name or account matches “\(query)”.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
        }
        .padding(Theme.Spacing.xl)
    }
}
