//
//  TokenListView.swift
//  Obsidium
//
//  The app's only main screen: a live list of tokens with a countdown,
//  swipe-to-delete, an empty state, and a + button to scan a new code.
//

import SwiftUI

struct TokenListView: View {
    @Environment(VaultStore.self) private var store
    @State private var isScannerPresented = false

    var body: some View {
        NavigationStack {
            Group {
                if store.accounts.isEmpty {
                    emptyState
                } else {
                    tokenList
                }
            }
            .navigationTitle("Obsidium")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isScannerPresented = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add token")
                }
            }
            .sheet(isPresented: $isScannerPresented) {
                ScannerScreen()
            }
        }
    }

    private var tokenList: some View {
        // One ticking clock drives every row so codes and rings stay in sync.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            List {
                ForEach(store.accounts) { account in
                    TokenRowView(account: account, now: context.date)
                }
                .onDelete { store.delete(at: $0) }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Tokens Yet", systemImage: "lock.shield")
        } description: {
            Text("Tap + to scan a 2FA QR code.")
        } actions: {
            Button("Scan QR Code") { isScannerPresented = true }
                .buttonStyle(.borderedProminent)
        }
    }
}
