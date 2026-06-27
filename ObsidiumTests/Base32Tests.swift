//
//  Base32Tests.swift
//  ObsidiumTests
//

import Testing
import Foundation
@testable import Obsidium

struct Base32Tests {

    @Test("RFC 4648 test vectors", arguments: [
        ("", ""),
        ("MY======", "f"),
        ("MZXQ====", "fo"),
        ("MZXW6===", "foo"),
        ("MZXW6YQ=", "foob"),
        ("MZXW6YTB", "fooba"),
        ("MZXW6YTBOI======", "foobar"),
    ])
    func knownVectors(encoded: String, decoded: String) {
        let result = Base32.decode(encoded)
        #expect(result == Data(decoded.utf8))
    }

    @Test("Lowercase and whitespace are tolerated")
    func tolerant() {
        #expect(Base32.decode("mzxw6ytb") == Data("fooba".utf8))
        #expect(Base32.decode("MZXW 6YTB") == Data("fooba".utf8))
    }

    @Test("A typical otpauth secret decodes")
    func realSecret() {
        // "JBSWY3DPEHPK3PXP" is a common example secret.
        #expect(Base32.decode("JBSWY3DPEHPK3PXP") != nil)
    }

    @Test("Invalid characters return nil")
    func invalid() {
        #expect(Base32.decode("0189") == nil)   // 0,1,8,9 are not in the alphabet
        #expect(Base32.decode("!!!!") == nil)
    }
}
