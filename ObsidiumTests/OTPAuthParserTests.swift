//
//  OTPAuthParserTests.swift
//  ObsidiumTests
//

import Testing
import Foundation
@testable import Obsidium

struct OTPAuthParserTests {

    @Test("Full URI with all parameters")
    func fullURI() throws {
        let uri = "otpauth://totp/GitHub:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&algorithm=SHA256&digits=8&period=60"
        let account = try OTPAuthParser.parse(uri)
        #expect(account.issuer == "GitHub")
        #expect(account.label == "alice@example.com")
        #expect(account.secret == "JBSWY3DPEHPK3PXP")
        #expect(account.algorithm == .sha256)
        #expect(account.digits == 8)
        #expect(account.period == 60)
    }

    @Test("Defaults applied when params omitted")
    func defaults() throws {
        let account = try OTPAuthParser.parse("otpauth://totp/Acme?secret=JBSWY3DPEHPK3PXP")
        #expect(account.algorithm == .sha1)
        #expect(account.digits == 6)
        #expect(account.period == 30)
    }

    @Test("Issuer from label prefix when no issuer query item")
    func issuerFromLabel() throws {
        let account = try OTPAuthParser.parse("otpauth://totp/Acme:bob?secret=JBSWY3DPEHPK3PXP")
        #expect(account.issuer == "Acme")
        #expect(account.label == "bob")
    }

    @Test("Percent-encoded label is decoded")
    func percentEncoded() throws {
        let account = try OTPAuthParser.parse("otpauth://totp/Big%20Corp:user%40mail.com?secret=JBSWY3DPEHPK3PXP")
        #expect(account.issuer == "Big Corp")
        #expect(account.label == "user@mail.com")
    }

    @Test("Rejects non-otpauth scheme")
    func rejectsWrongScheme() {
        #expect(throws: OTPAuthParseError.self) {
            try OTPAuthParser.parse("https://example.com")
        }
    }

    @Test("Rejects HOTP")
    func rejectsHOTP() {
        #expect(throws: OTPAuthParseError.self) {
            try OTPAuthParser.parse("otpauth://hotp/Acme?secret=JBSWY3DPEHPK3PXP&counter=0")
        }
    }

    @Test("Rejects missing secret")
    func rejectsMissingSecret() {
        #expect(throws: OTPAuthParseError.self) {
            try OTPAuthParser.parse("otpauth://totp/Acme?issuer=Acme")
        }
    }

    @Test("Rejects invalid secret")
    func rejectsInvalidSecret() {
        #expect(throws: OTPAuthParseError.self) {
            try OTPAuthParser.parse("otpauth://totp/Acme?secret=0189")
        }
    }
}
