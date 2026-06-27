//
//  Account.swift
//  Obsidium
//
//  The core data model for a single TOTP account. The full list of accounts is
//  Codable and persisted as one JSON blob in the Keychain (see KeychainVault).
//

import Foundation

/// Hash algorithm used by the HMAC step of TOTP generation.
///
/// Raw values match the `algorithm` parameter of an `otpauth://` URI so the
/// enum can be initialised directly from a parsed QR code.
enum OTPAlgorithm: String, Codable, Hashable, CaseIterable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
}

/// A single 2FA account and everything needed to generate its codes.
///
/// `secret` is stored exactly as imported (Base32, RFC 4648). The model is the
/// only thing persisted — there is no separate metadata store.
struct Account: Codable, Identifiable, Hashable {
    let id: UUID

    /// Service name, e.g. "GitHub". Taken from the `issuer` query item or the
    /// label prefix of the `otpauth://` URI.
    var issuer: String

    /// Account name within the service, e.g. "alice@example.com".
    var label: String

    /// Base32-encoded shared secret, uppercased, padding stripped.
    var secret: String

    var algorithm: OTPAlgorithm
    var digits: Int
    var period: Int

    init(
        id: UUID = UUID(),
        issuer: String,
        label: String,
        secret: String,
        algorithm: OTPAlgorithm = .sha1,
        digits: Int = 6,
        period: Int = 30
    ) {
        self.id = id
        self.issuer = issuer
        self.label = label
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
    }
}

extension Account {
    /// A human-friendly title for the row. Falls back to the label when the
    /// issuer is empty (some QR codes omit it).
    var displayTitle: String {
        issuer.isEmpty ? label : issuer
    }
}
