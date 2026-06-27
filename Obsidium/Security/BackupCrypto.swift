//
//  BackupCrypto.swift
//  Obsidium
//
//  Password-based encryption for backups. The password is stretched with
//  PBKDF2-HMAC-SHA256 (CommonCrypto) into a 256-bit key, which encrypts the
//  vault JSON with AES-GCM (CryptoKit). This is real authenticated encryption —
//  not an encoding — so a wrong password fails to decrypt rather than yielding
//  garbage.
//
//  File layout (binary):
//    "OBSD" | version(1) | saltLen(1) | salt | iterations(UInt32 BE) | AES-GCM combined
//

import Foundation
import CryptoKit
import CommonCrypto
import Security

enum BackupCrypto {
    private static let magic = Array("OBSD".utf8)
    private static let version: UInt8 = 1
    private static let iterations: UInt32 = 210_000
    private static let saltLength = 16

    enum CryptoError: LocalizedError {
        case randomFailed
        case keyDerivationFailed
        case badFormat
        case wrongPasswordOrCorrupt

        var errorDescription: String? {
            switch self {
            case .randomFailed, .keyDerivationFailed, .badFormat:
                return "Couldn't create the backup."
            case .wrongPasswordOrCorrupt:
                return "Wrong password, or the file is not a valid Obsidium backup."
            }
        }
    }

    // MARK: Encrypt

    static func encrypt(_ plaintext: Data, password: String) throws -> Data {
        var salt = Data(count: saltLength)
        let ok = salt.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, saltLength, buffer.baseAddress!)
        }
        guard ok == errSecSuccess else { throw CryptoError.randomFailed }

        let key = try deriveKey(password: password, salt: salt, iterations: iterations)
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else { throw CryptoError.badFormat }

        var out = Data()
        out.append(contentsOf: magic)
        out.append(version)
        out.append(UInt8(saltLength))
        out.append(salt)
        out.append(UInt8((iterations >> 24) & 0xFF))
        out.append(UInt8((iterations >> 16) & 0xFF))
        out.append(UInt8((iterations >> 8) & 0xFF))
        out.append(UInt8(iterations & 0xFF))
        out.append(combined)
        return out
    }

    // MARK: Decrypt

    static func decrypt(_ data: Data, password: String) throws -> Data {
        let bytes = [UInt8](data)
        var index = 0

        func read(_ count: Int) throws -> [UInt8] {
            guard index + count <= bytes.count else { throw CryptoError.badFormat }
            defer { index += count }
            return Array(bytes[index ..< index + count])
        }

        guard try read(magic.count) == magic else { throw CryptoError.badFormat }
        guard try read(1)[0] == version else { throw CryptoError.badFormat }
        let saltLen = Int(try read(1)[0])
        let salt = Data(try read(saltLen))
        let iterationBytes = try read(4)
        let iterations = iterationBytes.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        guard index <= bytes.count else { throw CryptoError.badFormat }
        let combined = Data(bytes[index ..< bytes.count])

        let key = try deriveKey(password: password, salt: salt, iterations: iterations)
        do {
            let box = try AES.GCM.SealedBox(combined: combined)
            return try AES.GCM.open(box, using: key)
        } catch {
            throw CryptoError.wrongPasswordOrCorrupt
        }
    }

    // MARK: Key derivation

    private static func deriveKey(password: String, salt: Data, iterations: UInt32) throws -> SymmetricKey {
        var derived = [UInt8](repeating: 0, count: 32)
        let status = salt.withUnsafeBytes { saltRaw -> Int32 in
            CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                password, password.utf8.count,
                saltRaw.bindMemory(to: UInt8.self).baseAddress, salt.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                iterations,
                &derived, derived.count
            )
        }
        guard Int(status) == kCCSuccess else { throw CryptoError.keyDerivationFailed }
        return SymmetricKey(data: Data(derived))
    }
}
