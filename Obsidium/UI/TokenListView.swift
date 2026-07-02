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
                if !isSearchPresented {
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
            }
            .modifier(SearchActivationModifier(text: $searchText, isPresented: $isSearchPresented))
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
            SearchResultsView(query: searchText, accounts: filteredAccounts)
                .transition(.opacity)
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

/// Attaches native search only while search mode is active. Keeping this
/// modifier off the normal screen prevents iOS from reserving or showing a
/// search bar until the explicit magnifying-glass button is tapped.
private struct SearchActivationModifier: ViewModifier {
    @Binding var text: String
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        if isPresented {
            content
                .searchable(
                    text: $text,
                    isPresented: $isPresented,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search tokens"
                )
                .onChange(of: isPresented) { _, presented in
                    if !presented { text = "" }
                }
        } else {
            content
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

/// Dedicated search mode. It deliberately replaces the Wallet deck so no normal
/// token cards, toolbar actions, codes, or icons are visible while searching.
private struct SearchResultsView: View {
    let query: String
    let accounts: [Account]

    @State private var expandedID: Account.ID?

    var body: some View {
        Group {
            if accounts.isEmpty {
                SearchEmptyState(query: query)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.md) {
                            ForEach(accounts) { account in
                                SearchTokenCard(
                                    account: account,
                                    now: context.date,
                                    isExpanded: expandedID == account.id
                                ) {
                                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                                        expandedID = expandedID == account.id ? nil : account.id
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
                        .padding(.bottom, Theme.Spacing.xxl)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .onChange(of: accounts.map(\.id)) { _, ids in
            if let id = expandedID, !ids.contains(id) { expandedID = nil }
        }
    }
}

private struct SearchTokenCard: View {
    let account: Account
    let now: Date
    let isExpanded: Bool
    let onToggle: () -> Void

    @Environment(ToastCenter.self) private var toast
    @State private var didCopy = false

    private var hasLabel: Bool { !account.label.isEmpty && account.displayTitle != account.label }
    private var code: String { TOTPGenerator.code(for: account, at: now) ?? "------" }
    private var hasCode: Bool { code != "------" }

    private var formattedCode: String {
        guard hasCode, code.count == 6 || code.count == 8 else {
            return hasCode ? code : "— — —"
        }
        let mid = code.index(code.startIndex, offsetBy: code.count / 2)
        return "\(code[..<mid]) \(code[mid...])"
    }

    private var secondsRemaining: Int { TOTPGenerator.secondsRemaining(period: account.period, at: now) }
    private var progress: Double { TOTPGenerator.progress(period: account.period, at: now) }

    private var brandIcon: BrandIcon {
        account.iconID.flatMap { BrandIcon.find(id: $0) }
            ?? BrandIcon.autodetect(for: account.issuer)
            ?? .default
    }

    private var brandTint: Color {
        let tint = brandIcon.tint ?? Theme.accent
        return tint.searchBrightness < 0.10 ? Color(white: 0.22) : tint
    }

    private var cardBackground: some View {
        let tint = brandTint
        let light = tint.searchBrightness > 0.62
        let top = tint.searchMixed(with: .black, amount: light ? 0.50 : 0.26)
        let bottom = tint.searchMixed(with: .black, amount: light ? 0.80 : 0.64)
        return LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? Theme.Spacing.lg : Theme.Spacing.xs) {
            nameBlock

            if isExpanded {
                codeRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.lg)
        .frame(minHeight: isExpanded ? 148 : 82)
        .background { cardBackground }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: brandTint.opacity(isExpanded ? 0.30 : 0.22), radius: isExpanded ? 16 : 12, y: isExpanded ? 8 : 6)
        .shadow(color: .black.opacity(0.28), radius: 5, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .onTapGesture { isExpanded ? copyCode() : onToggle() }
        .animation(.snappy, value: code)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(isExpanded ? "Double-tap to copy" : "Double-tap to reveal code")
    }

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(account.displayTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            if hasLabel {
                Text(account.label)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var codeRow: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            Text(formattedCode)
                .font(Theme.Typography.code)
                .tracking(4)
                .foregroundStyle(didCopy ? .white : .white.opacity(0.95))
                .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: Theme.Spacing.sm)
            CountdownRing(progress: progress, secondsRemaining: secondsRemaining, tint: .white)
        }
    }

    private var accessibilityText: String {
        isExpanded
            ? "\(account.displayTitle), code \(code)"
            : "\(account.displayTitle)\(hasLabel ? ", \(account.label)" : "")"
    }

    private func copyCode() {
        guard hasCode else { return }
        UIPasteboard.general.string = code
        Haptics.copy()
        toast.show("Code copied")
        withAnimation(.snappy) { didCopy = true }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.snappy) { didCopy = false }
        }
    }
}


private extension Color {
    var searchBrightness: CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b
    }

    func searchMixed(with other: Color, amount: CGFloat) -> Color {
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
