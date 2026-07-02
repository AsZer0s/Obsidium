//
//  AccountSearchTests.swift
//  ObsidiumTests
//

import Testing
@testable import Obsidium

struct AccountSearchTests {

    @Test("Empty query matches every account")
    func emptyQueryMatches() {
        let account = Account(issuer: "GitHub", label: "alice@example.com", secret: "JBSWY3DPEHPK3PXP")
        #expect(account.matchesSearch(""))
        #expect(account.matchesSearch("   "))
    }

    @Test("Search matches issuer and label case-insensitively")
    func matchesVisibleIdentity() {
        let account = Account(issuer: "Cloudflare", label: "Admin@Example.com", secret: "JBSWY3DPEHPK3PXP")
        #expect(account.matchesSearch("cloud"))
        #expect(account.matchesSearch("ADMIN@example"))
        #expect(!account.matchesSearch("github"))
    }

    @Test("Search does not match the secret")
    func doesNotMatchSecret() {
        let account = Account(issuer: "Acme", label: "alice", secret: "JBSWY3DPEHPK3PXP")
        #expect(!account.matchesSearch("JBSWY3"))
    }
}
