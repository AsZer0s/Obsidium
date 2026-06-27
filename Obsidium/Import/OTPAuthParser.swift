//
//  OTPAuthParser.swift
//  Obsidium
//
//  Parses an otpauth:// TOTP URI (RFC / Key Uri Format) into an Account.
//
//  Example:
//  otpauth://totp/GitHub:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&algorithm=SHA1&digits=6&period=30
//

import Foundation

enum OTPAuthParseError: LocalizedError {
    case notAnOTPAuthURI
    case unsupportedType        // we only support TOTP, not HOTP
    case missingSecret
    case invalidSecret

    var errorDescription: String? {
        switch self {
        case .notAnOTPAuthURI: return "This isn't a valid authenticator QR code."
        case .unsupportedType: return "Only time-based (TOTP) codes are supported."
        case .missingSecret:   return "The QR code is missing a secret."
        case .invalidSecret:   return "The QR code's secret is not valid."
        }
    }
}

enum OTPAuthParser {

    static func parse(_ string: String) throws -> Account {
        guard let components = URLComponents(string: string),
              components.scheme?.lowercased() == "otpauth" else {
            throw OTPAuthParseError.notAnOTPAuthURI
        }

        guard components.host?.lowercased() == "totp" else {
            throw OTPAuthParseError.unsupportedType
        }

        let queryItems = components.queryItems ?? []
        func value(_ name: String) -> String? {
            queryItems.first { $0.name.lowercased() == name }?.value
        }

        // Secret is required and must be valid Base32.
        guard let rawSecret = value("secret"), !rawSecret.isEmpty else {
            throw OTPAuthParseError.missingSecret
        }
        let secret = rawSecret.replacingOccurrences(of: " ", with: "").uppercased()
        guard let decoded = Base32.decode(secret), !decoded.isEmpty else {
            throw OTPAuthParseError.invalidSecret
        }

        // Label is the path, percent-decoded. May be "Issuer:account".
        let rawLabel = components.path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .removingPercentEncoding ?? components.path

        var issuer = value("issuer") ?? ""
        var label = rawLabel
        if let colon = rawLabel.firstIndex(of: ":") {
            let prefix = String(rawLabel[..<colon])
            let suffix = String(rawLabel[rawLabel.index(after: colon)...])
                .trimmingCharacters(in: .whitespaces)
            if issuer.isEmpty { issuer = prefix }
            label = suffix
        }

        let algorithm = value("algorithm")
            .flatMap { OTPAlgorithm(rawValue: $0.uppercased()) } ?? .sha1
        let digits = value("digits").flatMap { Int($0) } ?? 6
        let period = value("period").flatMap { Int($0) } ?? 30

        return Account(
            issuer: issuer,
            label: label,
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            period: period
        )
    }
}
