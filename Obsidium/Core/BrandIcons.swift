//
//  BrandIcons.swift
//  Obsidium
//
//  A curated library of brand icons for common MFA providers (using
//  SF Symbols that match brand visual cues, with a fallback general set).
//  Also provides auto-detection from issuer names.
//

import SwiftUI

/// A brand icon descriptor with ID, display name, symbol, color tint.
struct BrandIcon: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let tint: Color?
}

extension BrandIcon {
    /// Default icon if none selected.
    static let `default` = BrandIcon(id: "default", name: "Default", symbol: "lock.shield.fill", tint: Theme.accent)
}

extension BrandIcon {
    /// Full library of available brand icons, grouped by category.
    static let library: [BrandIcon] = [
        // Big tech platforms
        BrandIcon(id: "github", name: "GitHub", symbol: "chevron.left.forwardslash.chevron.right", tint: .white),
        BrandIcon(id: "gitlab", name: "GitLab", symbol: "flame.fill", tint: .orange),
        BrandIcon(id: "bitbucket", name: "Bitbucket", symbol: "circle.hexagongrid.fill", tint: .blue),

        // Cloud services
        BrandIcon(id: "aws", name: "AWS", symbol: "cloud.bolt.fill", tint: .orange),
        BrandIcon(id: "azure", name: "Azure", symbol: "square.grid.3x3.fill", tint: .blue),
        BrandIcon(id: "gcp", name: "Google Cloud", symbol: "cloud.square.fill", tint: .blue),
        BrandIcon(id: "digitalocean", name: "DigitalOcean", symbol: "drop.fill", tint: .blue),
        BrandIcon(id: "heroku", name: "Heroku", symbol: "leaf.fill", tint: .purple),
        BrandIcon(id: "vercel", name: "Vercel", symbol: "triangle.fill", tint: .black),
        BrandIcon(id: "netlify", name: "Netlify", symbol: "network", tint: .teal),
        BrandIcon(id: "firebase", name: "Firebase", symbol: "flame.fill", tint: .orange),

        // Social & communication
        BrandIcon(id: "google", name: "Google", symbol: "g.circle.fill", tint: .blue),
        BrandIcon(id: "microsoft", name: "Microsoft", symbol: "squareshape.split.2x2", tint: .blue),
        BrandIcon(id: "apple", name: "Apple", symbol: "apple.logo", tint: .black),
        BrandIcon(id: "facebook", name: "Facebook", symbol: "f.circle.fill", tint: .blue),
        BrandIcon(id: "instagram", name: "Instagram", symbol: "camera.aperture", tint: .purple),
        BrandIcon(id: "twitter", name: "X / Twitter", symbol: "xmark", tint: .black),
        BrandIcon(id: "linkedin", name: "LinkedIn", symbol: "person.2.fill", tint: .blue),
        BrandIcon(id: "telegram", name: "Telegram", symbol: "paperplane.fill", tint: .blue),
        BrandIcon(id: "discord", name: "Discord", symbol: "bubble.left.and.bubble.right.fill", tint: .purple),
        BrandIcon(id: "slack", name: "Slack", symbol: "bubble.left.and.bubble.right.fill", tint: .purple),

        // Finance & crypto
        BrandIcon(id: "stripe", name: "Stripe", symbol: "squareshape.on.squareshape.dashed", tint: .indigo),
        BrandIcon(id: "paypal", name: "PayPal", symbol: "creditcard.fill", tint: .blue),
        BrandIcon(id: "coinbase", name: "Coinbase", symbol: "bitcoinsign.circle.fill", tint: .blue),
        BrandIcon(id: "binance", name: "Binance", symbol: "circle.lefthalf.filled", tint: .yellow),
        BrandIcon(id: "binance", name: "Binance", symbol: "circle.lefthalf.filled", tint: .yellow),
        BrandIcon(id: "brave", name: "Brave", symbol: "leopard.fill", tint: .orange),

        // Identity & SSO
        BrandIcon(id: "auth0", name: "Auth0", symbol: "checkmark.shield.fill", tint: .orange),
        BrandIcon(id: "okta", name: "Okta", symbol: "key.keychain.fill", tint: .blue),
        BrandIcon(id: "1password", name: "1Password", symbol: "key.fill", tint: .blue),
        BrandIcon(id: "lastpass", name: "LastPass", symbol: "key.keychain.fill", tint: .red),
        BrandIcon(id: "dashlane", name: "Dashlane", symbol: "lock.fill", tint: .teal),
        BrandIcon(id: "bitwarden", name: "Bitwarden", symbol: "lock.shield.fill", tint: .blue),
        BrandIcon(id: "authy", name: "Authy", symbol: "checkmark.shield.fill", tint: .orange),
        BrandIcon(id: "duo", name: "Duo Security", symbol: "person.badge.shield.checkmark.fill", tint: .green),

        // Gaming & entertainment
        BrandIcon(id: "steam", name: "Steam", symbol: "gamecontroller.fill", tint: .black),
        BrandIcon(id: "epic", name: "Epic Games", symbol: "gamecontroller.fill", tint: .white),
        BrandIcon(id: "riot", name: "Riot Games", symbol: "flame.fill", tint: .orange),
        BrandIcon(id: "nintendo", name: "Nintendo", symbol: "gamecontroller.fill", tint: .red),
        BrandIcon(id: "sony", name: "PlayStation", symbol: "playstation.logosymbol", tint: .blue),
        BrandIcon(id: "xbox", name: "Xbox", symbol: "xbox.logosymbol", tint: .green),

        // Hosting & dev
        BrandIcon(id: "cloudflare", name: "Cloudflare", symbol: "bolt.shield.fill", tint: .orange),
        BrandIcon(id: "github", name: "GitHub", symbol: "chevron.left.forwardslash.chevron.right", tint: .white),
        BrandIcon(id: "notion", name: "Notion", symbol: "doc.plaintext.fill", tint: .black),
        BrandIcon(id: "figma", name: "Figma", symbol: "figure.2.circle", tint: .purple),
        BrandIcon(id: "linear", name: "Linear", symbol: "circle.and.line.horizontal", tint: .purple),

        // Email
        BrandIcon(id: "gmail", name: "Gmail", symbol: "envelope.fill", tint: .red),
        BrandIcon(id: "outlook", name: "Outlook", symbol: "envelope.fill", tint: .blue),
        BrandIcon(id: "proton", name: "ProtonMail", symbol: "envelope.badge.shield.half.filled", tint: .purple),
        BrandIcon(id: "tuta", name: "Tutanota", symbol: "tray.full.fill", tint: .red),
        BrandIcon(id: "fastmail", name: "Fastmail", symbol: "envelope.badge.fill", tint: .blue),

        // General fallback set
        BrandIcon(id: "shield", name: "Shield", symbol: "lock.shield.fill", tint: Theme.accent),
        BrandIcon(id: "key", name: "Key", symbol: "key.fill", tint: .orange),
        BrandIcon(id: "lock", name: "Lock", symbol: "lock.fill", tint: .gray),
        BrandIcon(id: "circle", name: "Circle", symbol: "circle.fill", tint: .gray),
        BrandIcon(id: "star", name: "Star", symbol: "star.fill", tint: .yellow),
        BrandIcon(id: "bolt", name: "Bolt", symbol: "bolt.fill", tint: .orange),
        BrandIcon(id: "leaf", name: "Leaf", symbol: "leaf.fill", tint: .green),
        BrandIcon(id: "heart", name: "Heart", symbol: "heart.fill", tint: .red),
        BrandIcon(id: "hexagon", name: "Hexagon", symbol: "hexagon.fill", tint: .purple),
        BrandIcon(id: "octagon", name: "Octagon", symbol: "octagon.fill", tint: .blue),
    ]

    /// Look up an icon by ID.
    static func find(id: String) -> BrandIcon? {
        library.first { $0.id == id }
    }

    /// Auto-detect the best icon for a given issuer name (case-insensitive).
    static func autodetect(for issuer: String) -> BrandIcon? {
        let lower = issuer.lowercased()

        // Exact matches first
        if lower.contains("github") { return find(id: "github") }
        if lower.contains("gitlab") { return find(id: "gitlab") }
        if lower.contains("bitbucket") { return find(id: "bitbucket") }
        if lower.contains("aws") || lower.contains("amazon") { return find(id: "aws") }
        if lower.contains("azure") { return find(id: "azure") }
        if lower.contains("gcp") || lower.contains("google cloud") { return find(id: "gcp") }
        if lower.contains("digitalocean") { return find(id: "digitalocean") }
        if lower.contains("heroku") { return find(id: "heroku") }
        if lower.contains("vercel") { return find(id: "vercel") }
        if lower.contains("netlify") { return find(id: "netlify") }
        if lower.contains("firebase") { return find(id: "firebase") }
        if lower.contains("google") && !lower.contains("cloud") { return find(id: "google") }
        if lower.contains("microsoft") || lower.contains("outlook") { return find(id: "microsoft") }
        if lower.contains("apple") && !lower.contains("appstore") { return find(id: "apple") }
        if lower.contains("facebook") { return find(id: "facebook") }
        if lower.contains("instagram") { return find(id: "instagram") }
        if lower.contains("twitter") || lower.contains("x.com") || lower.contains(" x "){ return find(id: "twitter") }
        if lower.contains("linkedin") { return find(id: "linkedin") }
        if lower.contains("telegram") { return find(id: "telegram") }
        if lower.contains("discord") { return find(id: "discord") }
        if lower.contains("slack") { return find(id: "slack") }
        if lower.contains("stripe") { return find(id: "stripe") }
        if lower.contains("paypal") { return find(id: "paypal") }
        if lower.contains("coinbase") { return find(id: "coinbase") }
        if lower.contains("binance") { return find(id: "binance") }
        if lower.contains("brave") { return find(id: "brave") }
        if lower.contains("auth0") { return find(id: "auth0") }
        if lower.contains("okta") { return find(id: "okta") }
        if lower.contains("1password") { return find(id: "1password") }
        if lower.contains("lastpass") { return find(id: "lastpass") }
        if lower.contains("dashlane") { return find(id: "dashlane") }
        if lower.contains("bitwarden") { return find(id: "bitwarden") }
        if lower.contains("authy") { return find(id: "authy") }
        if lower.contains("duo") { return find(id: "duo") }
        if lower.contains("steam") { return find(id: "steam") }
        if lower.contains("epic games") || lower.contains("epic") { return find(id: "epic") }
        if lower.contains("riot games") || lower.contains("riot") { return find(id: "riot") }
        if lower.contains("nintendo") { return find(id: "nintendo") }
        if lower.contains("playstation") || lower.contains("sony") { return find(id: "sony") }
        if lower.contains("xbox") { return find(id: "xbox") }
        if lower.contains("cloudflare") { return find(id: "cloudflare") }
        if lower.contains("notion") { return find(id: "notion") }
        if lower.contains("figma") { return find(id: "figma") }
        if lower.contains("linear") { return find(id: "linear") }
        if lower.contains("gmail") { return find(id: "gmail") }
        if lower.contains("proton") || lower.contains("protonmail") { return find(id: "proton") }
        if lower.contains("tutanota") || lower.contains("tuta") { return find(id: "tuta") }
        if lower.contains("fastmail") { return find(id: "fastmail") }

        return nil
    }
}
