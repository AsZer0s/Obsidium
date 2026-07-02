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
                ToolbarItem(placement: .topBarTrailing) {
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
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search tokens"
            )
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
        if store.accounts.isEmpty {
            EmptyStateView { isAddOptionsPresented = true }
        } else if filteredAccounts.isEmpty {
            SearchEmptyState(query: searchText)
        } else {
            // One ticking clock drives every card so codes and rings stay in sync.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                CardStack(
                    accounts: filteredAccounts,
                    now: context.date
                )
            }
        }
    }

    private func presentManualAdd() {
        manualDraft = Account(issuer: "", label: "", secret: "")
        isManualAddPresented = true
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

/// Shown when search is active but no token identity matches.
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
            Text("No token name or account matches “\(query)”.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
        }
        .padding(Theme.Spacing.xl)
    }
}
