//
//  TOTPGeneratorTests.swift
//  ObsidiumTests
//
//  Validates code generation against the RFC 6238 Appendix B test vectors.
//  Those vectors specify the secret as an ASCII seed used directly as the HMAC
//  key, so we call the raw-key entry point (bypassing Base32).
//

import Testing
import Foundation
@testable import Obsidium

struct TOTPGeneratorTests {

    // RFC 6238 Appendix B seeds (ASCII), repeated/truncated to key length.
    private let seedSHA1 = Data("12345678901234567890".utf8)                                   // 20 bytes
    private let seedSHA256 = Data("12345678901234567890123456789012".utf8)                     // 32 bytes
    private let seedSHA512 = Data("1234567890123456789012345678901234567890123456789012345678901234".utf8) // 64 bytes

    private func code(time: TimeInterval, algorithm: OTPAlgorithm, key: Data) -> String {
        let counter = TOTPGenerator.counter(for: Date(timeIntervalSince1970: time), period: 30)
        return TOTPGenerator.code(key: key, counter: counter, algorithm: algorithm, digits: 8)
    }

    @Test("RFC 6238 SHA1 vectors", arguments: [
        (59.0, "94287082"),
        (1111111109.0, "07081804"),
        (1111111111.0, "14050471"),
        (1234567890.0, "89005924"),
        (2000000000.0, "69279037"),
        (20000000000.0, "65353130"),
    ])
    func sha1Vectors(time: TimeInterval, expected: String) {
        #expect(code(time: time, algorithm: .sha1, key: seedSHA1) == expected)
    }

    @Test("RFC 6238 SHA256 vectors", arguments: [
        (59.0, "46119246"),
        (1111111109.0, "68084774"),
        (1234567890.0, "91819424"),
        (20000000000.0, "77737706"),
    ])
    func sha256Vectors(time: TimeInterval, expected: String) {
        #expect(code(time: time, algorithm: .sha256, key: seedSHA256) == expected)
    }

    @Test("RFC 6238 SHA512 vectors", arguments: [
        (59.0, "90693936"),
        (1111111111.0, "99943326"),
        (1234567890.0, "93441116"),
        (20000000000.0, "47863826"),
    ])
    func sha512Vectors(time: TimeInterval, expected: String) {
        #expect(code(time: time, algorithm: .sha512, key: seedSHA512) == expected)
    }

    @Test("Code length matches requested digits")
    func digitsPadding() {
        let counter = TOTPGenerator.counter(for: Date(timeIntervalSince1970: 0), period: 30)
        #expect(TOTPGenerator.code(key: seedSHA1, counter: counter, algorithm: .sha1, digits: 6).count == 6)
        #expect(TOTPGenerator.code(key: seedSHA1, counter: counter, algorithm: .sha1, digits: 8).count == 8)
    }

    @Test("Invalid Base32 secret yields nil")
    func invalidSecretReturnsNil() {
        let account = Account(issuer: "X", label: "y", secret: "0189!!", digits: 6, period: 30)
        #expect(TOTPGenerator.code(for: account) == nil)
    }

    @Test("Countdown decreases within a step")
    func countdownHelpers() {
        // 10s into a 30s step -> 20s remaining, progress 20/30.
        let date = Date(timeIntervalSince1970: 10)
        #expect(TOTPGenerator.secondsRemaining(period: 30, at: date) == 20)
        #expect(abs(TOTPGenerator.progress(period: 30, at: date) - (20.0 / 30.0)) < 0.0001)
    }
}
