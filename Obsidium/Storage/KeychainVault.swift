//
//  KeychainVault.swift
//  Obsidium
//
//  Persists the entire account list as a single JSON blob in the iOS Keychain.
//  Device-only accessibility (never iCloud-synced) enforces the offline-first,
//  no-sync philosophy. This type is the only thing that touches the Keychain.
//

import Foundation
import Security

enum KeychainError: Error {
    /// A non-success, non-"not found" OSStatus from the Security framework.
    case unexpectedStatus(OSStatus)
    /// Stored bytes could not be decoded back into `[Account]`.
    case decodingFailed
}

struct KeychainVault {

    // A single generic-password item identified by (service, account).
    private let service = "com.obsidium.vault"
    private let account = "tokens"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Load the stored accounts. Returns an empty array when nothing has been
    /// saved yet (first launch).
    func load() throws -> [Account] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { throw KeychainError.decodingFailed }
            do {
                return try decoder.decode([Account].self, from: data)
            } catch {
                throw KeychainError.decodingFailed
            }
        case errSecItemNotFound:
            return []
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Persist the accounts, replacing whatever was stored before. Upserts:
    /// updates the existing item or adds it if absent.
    func save(_ accounts: [Account]) throws {
        let data = try encoder.encode(accounts)

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        // Try to update first.
        let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributesToUpdate as CFDictionary)

        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            // No existing item — add a new one with device-only accessibility.
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        default:
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }
}
