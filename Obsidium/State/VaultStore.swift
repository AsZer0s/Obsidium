//
//  VaultStore.swift
//  Obsidium
//
//  The single source of truth for the app's accounts. Holds the array in
//  memory, mediates between the UI and the Keychain, and persists on every
//  mutation. Views observe this; they never touch KeychainVault directly.
//

import Foundation
import Observation

@Observable
final class VaultStore {

    /// The current accounts, ordered as displayed.
    private(set) var accounts: [Account] = []

    /// Set when a load/save fails so the UI can surface it. Cleared on success.
    var lastError: String?

    private let vault = KeychainVault()

    /// Load persisted accounts into memory. Call once on launch.
    func load() {
        do {
            accounts = try vault.load()
            lastError = nil
        } catch {
            lastError = "Could not read saved tokens."
        }
    }

    /// Add a new account (ignoring exact duplicates of an existing secret +
    /// issuer pair) and persist.
    func add(_ account: Account) {
        let isDuplicate = accounts.contains {
            $0.secret == account.secret && $0.issuer == account.issuer && $0.label == account.label
        }
        guard !isDuplicate else { return }
        accounts.append(account)
        persist()
    }

    /// Remove the accounts at the given offsets (List `onDelete`/swipe) and persist.
    func delete(at offsets: IndexSet) {
        accounts.remove(atOffsets: offsets)
        persist()
    }

    /// Remove a specific account and persist.
    func delete(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        persist()
    }

    private func persist() {
        do {
            try vault.save(accounts)
            lastError = nil
        } catch {
            lastError = "Could not save tokens."
        }
    }
}
