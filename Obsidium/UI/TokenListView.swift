//
//  TokenListView.swift
//  Obsidium
//
//  The app's only main screen: a dark, card-based list of tokens with a live
//  countdown, swipe-to-delete, a designed empty state, and a + button to scan.
//

import SwiftUI

struct TokenListView: View {
    @Environment(VaultStore.self) private var store
    @State private var isScannerPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Obsidium")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isScannerPresented = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                    .tint(Theme.accent)
                    .accessibilityLabel("Add token")
                }
            }
            .sheet(isPresented: $isScannerPresented) {
                ScannerScreen()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.accounts.isEmpty {
            EmptyStateView { isScannerPresented = true }
        } else {
            tokenList
        }
    }

    private var tokenList: some View {
        // One ticking clock drives every card so codes and rings stay in sync.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            List {
                ForEach(store.accounts) { account in
                    TokenCardView(account: account, now: context.date)
                        .listRowInsets(EdgeInsets(
                            top: Theme.Spacing.sm - 2, leading: Theme.Spacing.lg,
                            bottom: Theme.Spacing.sm - 2, trailing: Theme.Spacing.lg
                        ))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.delete(account)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
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
                Text("Scan a 2FA QR code to add your first secure token.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            Button(action: onScan) {
                Label("Scan QR Code", systemImage: "qrcode.viewfinder")
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
