//
//  TOTPGenerator.swift
//  Obsidium
//
//  RFC 6238 (TOTP) on top of RFC 4226 (HOTP) dynamic truncation, using
//  CryptoKit's HMAC. Stateless — a namespace of free functions.
//

import Foundation
import CryptoKit

enum TOTPGenerator {

    /// Generate the current code for an account at the given instant.
    ///
    /// Returns a zero-padded, `digits`-long string, or `nil` if the secret is
    /// not valid Base32.
    static func code(for account: Account, at date: Date = Date()) -> String? {
        guard let key = Base32.decode(account.secret), !key.isEmpty else {
            return nil
        }
        let counter = counter(for: date, period: account.period)
        return code(key: key, counter: counter, algorithm: account.algorithm, digits: account.digits)
    }

    /// Time-step counter `T = floor(unixTime / period)`.
    static func counter(for date: Date, period: Int) -> UInt64 {
        let seconds = max(0, date.timeIntervalSince1970)
        return UInt64(seconds) / UInt64(max(1, period))
    }

    /// Core HOTP computation. Exposed (with a raw key) so unit tests can feed
    /// the RFC 6238 Appendix B ASCII seed directly, bypassing Base32.
    static func code(key: Data, counter: UInt64, algorithm: OTPAlgorithm, digits: Int) -> String {
        // Counter as 8-byte big-endian message.
        var bigEndianCounter = counter.bigEndian
        let message = withUnsafeBytes(of: &bigEndianCounter) { Data($0) }

        let hmac = hmac(key: key, message: message, algorithm: algorithm)

        // RFC 4226 §5.3 dynamic truncation.
        let offset = Int(hmac[hmac.count - 1] & 0x0F)
        let binary =
            (UInt32(hmac[offset]     & 0x7F) << 24) |
            (UInt32(hmac[offset + 1] & 0xFF) << 16) |
            (UInt32(hmac[offset + 2] & 0xFF) << 8)  |
            (UInt32(hmac[offset + 3] & 0xFF))

        let modulus = UInt32(pow(10, Double(digits)))
        let otp = binary % modulus
        return String(format: "%0\(digits)d", otp)
    }

    /// Runtime-selected HMAC. Note CryptoKit places SHA-1 under `Insecure`.
    private static func hmac(key: Data, message: Data, algorithm: OTPAlgorithm) -> [UInt8] {
        let symmetricKey = SymmetricKey(data: key)
        switch algorithm {
        case .sha1:
            return Array(HMAC<Insecure.SHA1>.authenticationCode(for: message, using: symmetricKey))
        case .sha256:
            return Array(HMAC<SHA256>.authenticationCode(for: message, using: symmetricKey))
        case .sha512:
            return Array(HMAC<SHA512>.authenticationCode(for: message, using: symmetricKey))
        }
    }

    // MARK: - Countdown helpers

    /// Whole seconds remaining in the current time step (1...period).
    static func secondsRemaining(period: Int, at date: Date = Date()) -> Int {
        let p = max(1, period)
        let elapsed = Int(date.timeIntervalSince1970) % p
        return p - elapsed
    }

    /// Progress through the current time step as 0...1, where 1 means a fresh
    /// step and the value decreases toward 0 as it expires.
    static func progress(period: Int, at date: Date = Date()) -> Double {
        let p = Double(max(1, period))
        let elapsed = date.timeIntervalSince1970.truncatingRemainder(dividingBy: p)
        return (p - elapsed) / p
    }
}
