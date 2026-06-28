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
        // MARK: Big Tech & Social
        BrandIcon(id: "github", name: "GitHub", symbol: "chevron.left.forwardslash.chevron.right", tint: .white),
        BrandIcon(id: "gitlab", name: "GitLab", symbol: "flame.fill", tint: .orange),
        BrandIcon(id: "bitbucket", name: "Bitbucket", symbol: "circle.hexagongrid.fill", tint: .blue),
        BrandIcon(id: "google", name: "Google", symbol: "g.circle.fill", tint: .blue),
        BrandIcon(id: "google-cloud", name: "Google Cloud", symbol: "cloud.square.fill", tint: .blue),
        BrandIcon(id: "gmail", name: "Gmail", symbol: "envelope.fill", tint: .red),
        BrandIcon(id: "microsoft", name: "Microsoft", symbol: "squareshape.split.2x2", tint: .blue),
        BrandIcon(id: "outlook", name: "Outlook", symbol: "envelope.fill", tint: .blue),
        BrandIcon(id: "azure", name: "Azure", symbol: "square.grid.3x3.fill", tint: .blue),
        BrandIcon(id: "apple", name: "Apple", symbol: "apple.logo", tint: .black),
        BrandIcon(id: "apple-id", name: "Apple ID", symbol: "apple.logo", tint: .black),
        BrandIcon(id: "icloud", name: "iCloud", symbol: "icloud.fill", tint: .blue),
        BrandIcon(id: "facebook", name: "Facebook", symbol: "f.circle.fill", tint: .blue),
        BrandIcon(id: "instagram", name: "Instagram", symbol: "camera.aperture", tint: .purple),
        BrandIcon(id: "whatsapp", name: "WhatsApp", symbol: "phone.bubble.left.fill", tint: .green),
        BrandIcon(id: "telegram", name: "Telegram", symbol: "paperplane.fill", tint: .blue),
        BrandIcon(id: "discord", name: "Discord", symbol: "bubble.left.and.bubble.right.fill", tint: .purple),
        BrandIcon(id: "slack", name: "Slack", symbol: "bubble.left.and.bubble.right.fill", tint: .purple),
        BrandIcon(id: "twitter", name: "X / Twitter", symbol: "xmark", tint: .black),
        BrandIcon(id: "x-twitter", name: "X / Twitter", symbol: "xmark", tint: .black),
        BrandIcon(id: "linkedin", name: "LinkedIn", symbol: "person.2.fill", tint: .blue),
        BrandIcon(id: "reddit", name: "Reddit", symbol: "alien", tint: .orange),
        BrandIcon(id: "tiktok", name: "TikTok", symbol: "play.rectangle.fill", tint: .black),
        BrandIcon(id: "youtube", name: "YouTube", symbol: "play.rectangle.fill", tint: .red),
        BrandIcon(id: "twitch", name: "Twitch", symbol: "play.rectangle.fill", tint: .purple),
        BrandIcon(id: "amazon", name: "Amazon", symbol: "a.circle.fill", tint: .orange),
        BrandIcon(id: "aws", name: "AWS", symbol: "cloud.bolt.fill", tint: .orange),
        BrandIcon(id: "amazon-aws", name: "AWS", symbol: "cloud.bolt.fill", tint: .orange),

        // MARK: Cloud Providers & Hosting
        BrandIcon(id: "cloudflare", name: "Cloudflare", symbol: "bolt.shield.fill", tint: .orange),
        BrandIcon(id: "vercel", name: "Vercel", symbol: "triangle.fill", tint: .black),
        BrandIcon(id: "netlify", name: "Netlify", symbol: "network", tint: .teal),
        BrandIcon(id: "heroku", name: "Heroku", symbol: "leaf.fill", tint: .purple),
        BrandIcon(id: "digitalocean", name: "DigitalOcean", symbol: "drop.fill", tint: .blue),
        BrandIcon(id: "linode", name: "Linode", symbol: "server.rack", tint: .blue),
        BrandIcon(id: "vultr", name: "Vultr", symbol: "network", tint: .teal),
        BrandIcon(id: "hetzner", name: "Hetzner", symbol: "server.rack", tint: .orange),
        BrandIcon(id: "ovh", name: "OVH", symbol: "server.rack", tint: .blue),
        BrandIcon(id: "scaleway", name: "Scaleway", symbol: "scale.3d", tint: .yellow),
        BrandIcon(id: "render", name: "Render", symbol: "play.rectangle.fill", tint: .teal),
        BrandIcon(id: "flyio", name: "Fly.io", symbol: "paperplane.fill", tint: .indigo),
        BrandIcon(id: "railway", name: "Railway", symbol: "train.side.front.car", tint: .purple),
        BrandIcon(id: "supabase", name: "Supabase", symbol: "circle.and.line.horizontal", tint: .green),
        BrandIcon(id: "firebase", name: "Firebase", symbol: "flame.fill", tint: .orange),
        BrandIcon(id: "planetscale", name: "PlanetScale", symbol: "circle.hexagongrid.fill", tint: .blue),
        BrandIcon(id: "neon", name: "Neon", symbol: "glow", tint: .green),
        BrandIcon(id: "turso", name: "Turso", symbol: "globe.americas.fill", tint: .purple),
        BrandIcon(id: "supabase", name: "Supabase", symbol: "circle.and.line.horizontal", tint: .green),
        BrandIcon(id: "surrealdb", name: "SurrealDB", symbol: "globe.europe.fill", tint: .blue),
        BrandIcon(id: "mongodb", name: "MongoDB", symbol: "leaf.fill", tint: .green),
        BrandIcon(id: "mongodb", name: "MongoDB Atlas", symbol: "leaf.fill", tint: .green),
        BrandIcon(id: "postgresql", name: "PostgreSQL", symbol: "tray.full.fill", tint: .blue),
        BrandIcon(id: "mysql", name: "MySQL", symbol: "tray.full.fill", tint: .orange),
        BrandIcon(id: "cockroachdb", name: "CockroachDB", symbol: "ant.fill", tint: .red),
        BrandIcon(id: "redis", name: "Redis", symbol: "cube.fill", tint: .red),
        BrandIcon(id: "elasticsearch", name: "Elasticsearch", symbol: "magnifyingglass.circle.fill", tint: .blue),
        BrandIcon(id: "kibana", name: "Kibana", symbol: "magnifyingglass.circle.fill", tint: .blue),

        // MARK: CDNs & Edge
        BrandIcon(id: "cloudflare", name: "Cloudflare", symbol: "bolt.shield.fill", tint: .orange),
        BrandIcon(id: "fastly", name: "Fastly", symbol: "bolt.fill", tint: .red),
        BrandIcon(id: "akamai", name: "Akamai", symbol: "globe.americas.fill", tint: .red),
        BrandIcon(id: "vercel-edge", name: "Vercel Edge", symbol: "triangle.fill", tint: .black),
        BrandIcon(id: "netlify-edge", name: "Netlify Edge", symbol: "network", tint: .teal),

        // MARK: Dev Tools & SaaS
        BrandIcon(id: "notion", name: "Notion", symbol: "doc.plaintext.fill", tint: .black),
        BrandIcon(id: "figma", name: "Figma", symbol: "figure.2.circle", tint: .purple),
        BrandIcon(id: "linear", name: "Linear", symbol: "circle.and.line.horizontal", tint: .purple),
        BrandIcon(id: "asana", name: "Asana", symbol: "checkmark.circle.fill", tint: .red),
        BrandIcon(id: "jira", name: "Jira", symbol: "tray.full.fill", tint: .blue),
        BrandIcon(id: "trello", name: "Trello", symbol: "square.grid.3x3.fill", tint: .blue),
        BrandIcon(id: "slack", name: "Slack", symbol: "bubble.left.and.bubble.right.fill", tint: .purple),
        BrandIcon(id: "discord", name: "Discord", symbol: "bubble.left.and.bubble.right.fill", tint: .purple),
        BrandIcon(id: "zoom", name: "Zoom", symbol: "video.fill", tint: .blue),
        BrandIcon(id: "teams", name: "Microsoft Teams", symbol: "bubble.left.and.bubble.right.fill", tint: .purple),
        BrandIcon(id: "meet", name: "Google Meet", symbol: "video.fill", tint: .green),
        BrandIcon(id: "dropbox", name: "Dropbox", symbol: "square.and.arrow.up.on.square.fill", tint: .blue),
        BrandIcon(id: "box", name: "Box", symbol: "cube.fill", tint: .blue),
        BrandIcon(id: "onedrive", name: "OneDrive", symbol: "tray.full.fill", tint: .blue),
        BrandIcon(id: "googledrive", name: "Google Drive", symbol: "square.grid.3x3.fill", tint: .green),
        BrandIcon(id: "pcloud", name: "pCloud", symbol: "cloud.fill", tint: .blue),
        BrandIcon(id: "proton-drive", name: "Proton Drive", symbol: "tray.full.fill", tint: .purple),
        BrandIcon(id: "obsidian", name: "Obsidian", symbol: "doc.text.image.fill", tint: .purple),

        // MARK: Email Providers
        BrandIcon(id: "gmail", name: "Gmail", symbol: "envelope.fill", tint: .red),
        BrandIcon(id: "googlemail", name: "Google Mail", symbol: "envelope.fill", tint: .red),
        BrandIcon(id: "outlook", name: "Outlook", symbol: "envelope.fill", tint: .blue),
        BrandIcon(id: "hotmail", name: "Hotmail", symbol: "envelope.fill", tint: .orange),
        BrandIcon(id: "livemail", name: "Live Mail", symbol: "envelope.fill", tint: .blue),
        BrandIcon(id: "proton", name: "ProtonMail", symbol: "envelope.badge.shield.half.filled", tint: .purple),
        BrandIcon(id: "protonmail", name: "ProtonMail", symbol: "envelope.badge.shield.half.filled", tint: .purple),
        BrandIcon(id: "tutanota", name: "Tutanota", symbol: "tray.full.fill", tint: .red),
        BrandIcon(id: "tuta", name: "Tuta", symbol: "tray.full.fill", tint: .red),
        BrandIcon(id: "fastmail", name: "Fastmail", symbol: "envelope.badge.fill", tint: .blue),
        BrandIcon(id: "hey", name: "Hey", symbol: "hand.thumbsup.fill", tint: .blue),
        BrandIcon(id: "icloud-mail", name: "iCloud Mail", symbol: "icloud.fill", tint: .blue),
        BrandIcon(id: "zoho-mail", name: "Zoho Mail", symbol: "envelope.fill", tint: .orange),
        BrandIcon(id: "yandex", name: "Yandex Mail", symbol: "envelope.fill", tint: .red),
        BrandIcon(id: "mailfence", name: "Mailfence", symbol: "envelope.shield.fill", tint: .teal),
        BrandIcon(id: "mailbox", name: "Mailbox", symbol: "mailbox.fill", tint: .blue),

        // MARK: Forums & Communities
        BrandIcon(id: "reddit", name: "Reddit", symbol: "alien", tint: .orange),
        BrandIcon(id: "stackoverflow", name: "Stack Overflow", symbol: "paperclip.fill", tint: .orange),
        BrandIcon(id: "stackoverflow", name: "Stack Overflow", symbol: "doc.on.doc.fill", tint: .orange),
        BrandIcon(id: "github-discussions", name: "GitHub Discussions", symbol: "bubble.left.and.bubble.right.fill", tint: .white),
        BrandIcon(id: "discourse", name: "Discourse", symbol: "bubble.left.and.bubble.right.fill", tint: .teal),
        BrandIcon(id: "phpbb", name: "phpBB", symbol: "bubble.left.and.bubble.right.fill", tint: .purple),
        BrandIcon(id: "nodebb", name: "NodeBB", symbol: "bubble.left.and.bubble.right.fill", tint: .green),
        BrandIcon(id: "discord-forum", name: "Discord Forum", symbol: "bubble.left.and.bubble.right.fill", tint: .purple),
        BrandIcon(id: "patreon", name: "Patreon", symbol: "person.fill", tint: .orange),
        BrandIcon(id: "kofi", name: "Ko-fi", symbol: "cup.and.saucer.fill", tint: .yellow),
        BrandIcon(id: "discord-community", name: "Discord Community", symbol: "bubble.left.and.bubble.right.fill", tint: .purple),

        // MARK: Security & Auth
        BrandIcon(id: "auth0", name: "Auth0", symbol: "checkmark.shield.fill", tint: .orange),
        BrandIcon(id: "okta", name: "Okta", symbol: "key.keychain.fill", tint: .blue),
        BrandIcon(id: "onepassword", name: "1Password", symbol: "key.fill", tint: .blue),
        BrandIcon(id: "bitwarden", name: "Bitwarden", symbol: "lock.shield.fill", tint: .blue),
        BrandIcon(id: "lastpass", name: "LastPass", symbol: "key.keychain.fill", tint: .red),
        BrandIcon(id: "dashlane", name: "Dashlane", symbol: "lock.fill", tint: .teal),
        BrandIcon(id: "authy", name: "Authy", symbol: "checkmark.shield.fill", tint: .orange),
        BrandIcon(id: "duo", name: "Duo Security", symbol: "person.badge.shield.checkmark.fill", tint: .green),
        BrandIcon(id: "microsoft-authenticator", name: "Microsoft Authenticator", symbol: "lock.shield.fill", tint: .blue),
        BrandIcon(id: "google-authenticator", name: "Google Authenticator", symbol: "lock.shield.fill", tint: .blue),
        BrandIcon(id: "andotp", name: "andOTP", symbol: "lock.fill", tint: .green),
        BrandIcon(id: "authenticator-pro", name: "Authenticator Pro", symbol: "lock.shield.fill", tint: .blue),

        // MARK: Finance & Payments
        BrandIcon(id: "stripe", name: "Stripe", symbol: "squareshape.on.squareshape.dashed", tint: .indigo),
        BrandIcon(id: "paypal", name: "PayPal", symbol: "creditcard.fill", tint: .blue),
        BrandIcon(id: "coinbase", name: "Coinbase", symbol: "bitcoinsign.circle.fill", tint: .blue),
        BrandIcon(id: "binance", name: "Binance", symbol: "circle.lefthalf.filled", tint: .yellow),
        BrandIcon(id: "kraken", name: "Kraken", symbol: "circle.hexagongrid.fill", tint: .purple),
        BrandIcon(id: "gemini", name: "Gemini", symbol: "atom", tint: .teal),
        BrandIcon(id: "coinlist", name: "CoinList", symbol: "list.bullet", tint: .green),
        BrandIcon(id: "ledger", name: "Ledger", symbol: "shield.lefthalf.filled", tint: .purple),
        BrandIcon(id: "trezor", name: "Trezor", symbol: "lock.shield.fill", tint: .green),
        BrandIcon(id: "metamask", name: "MetaMask", symbol: "fox.fill", tint: .orange),
        BrandIcon(id: "brave", name: "Brave", symbol: "leopard.fill", tint: .orange),
        BrandIcon(id: "wise", name: "Wise", symbol: "tray.full.fill", tint: .teal),
        BrandIcon(id: "revolut", name: "Revolut", symbol: "creditcard.fill", tint: .yellow),
        BrandIcon(id: "transferwise", name: "Wise (TransferWise)", symbol: "tray.full.fill", tint: .teal),
        BrandIcon(id: "squirrel", name: "Squirrel", symbol: "squirrel.fill", tint: .orange),

        // MARK: Gaming & Entertainment
        BrandIcon(id: "steam", name: "Steam", symbol: "gamecontroller.fill", tint: .black),
        BrandIcon(id: "epic", name: "Epic Games", symbol: "gamecontroller.fill", tint: .white),
        BrandIcon(id: "riot", name: "Riot Games", symbol: "flame.fill", tint: .red),
        BrandIcon(id: "nintendo", name: "Nintendo", symbol: "gamecontroller.fill", tint: .red),
        BrandIcon(id: "playstation", name: "PlayStation", symbol: "playstation.logosymbol", tint: .blue),
        BrandIcon(id: "sony", name: "PlayStation", symbol: "playstation.logosymbol", tint: .blue),
        BrandIcon(id: "xbox", name: "Xbox", symbol: "xbox.logosymbol", tint: .green),
        BrandIcon(id: "battle.net", name: "Battle.net", symbol: "gamecontroller.fill", tint: .blue),
        BrandIcon(id: "ubisoft", name: "Ubisoft", symbol: "gamecontroller.fill", tint: .blue),
        BrandIcon(id: "ea", name: "EA", symbol: "gamecontroller.fill", tint: .orange),
        BrandIcon(id: "rockstar", name: "Rockstar Games", symbol: "star.fill", tint: .yellow),
        BrandIcon(id: "origin", name: "Origin", symbol: "gamecontroller.fill", tint: .orange),
        BrandIcon(id: "uplay", name: "Ubisoft Connect", symbol: "gamecontroller.fill", tint: .blue),
        BrandIcon(id: "epic-games", name: "Epic Games Store", symbol: "gamecontroller.fill", tint: .white),
        BrandIcon(id: "gog", name: "GOG Galaxy", symbol: "gamecontroller.fill", tint: .purple),
        BrandIcon(id: "itch", name: "itch.io", symbol: "gamecontroller.fill", tint: .yellow),

        // MARK: Infrastructure & PaaS
        BrandIcon(id: "aws", name: "AWS", symbol: "cloud.bolt.fill", tint: .orange),
        BrandIcon(id: "aws-iam", name: "AWS IAM", symbol: "person.badge.key.fill", tint: .orange),
        BrandIcon(id: "gcp", name: "Google Cloud", symbol: "cloud.square.fill", tint: .blue),
        BrandIcon(id: "google-cloud", name: "Google Cloud Platform", symbol: "cloud.square.fill", tint: .blue),
        BrandIcon(id: "azure", name: "Azure", symbol: "square.grid.3x3.fill", tint: .blue),
        BrandIcon(id: "digitalocean", name: "DigitalOcean", symbol: "drop.fill", tint: .blue),
        BrandIcon(id: "heroku", name: "Heroku", symbol: "leaf.fill", tint: .purple),
        BrandIcon(id: "vercel", name: "Vercel", symbol: "triangle.fill", tint: .black),
        BrandIcon(id: "netlify", name: "Netlify", symbol: "network", tint: .teal),
        BrandIcon(id: "render", name: "Render", symbol: "play.rectangle.fill", tint: .teal),
        BrandIcon(id: "flyio", name: "Fly.io", symbol: "paperplane.fill", tint: .indigo),
        BrandIcon(id: "railway", name: "Railway", symbol: "train.side.front.car", tint: .purple),
        BrandIcon(id: "planetscale", name: "PlanetScale", symbol: "circle.hexagongrid.fill", tint: .blue),
        BrandIcon(id: "supabase", name: "Supabase", symbol: "circle.and.line.horizontal", tint: .green),
        BrandIcon(id: "firebase", name: "Firebase", symbol: "flame.fill", tint: .orange),
        BrandIcon(id: "cloudflare", name: "Cloudflare", symbol: "bolt.shield.fill", tint: .orange),
        BrandIcon(id: "vercel-edge", name: "Vercel Edge", symbol: "triangle.fill", tint: .black),
        BrandIcon(id: "netlify-edge", name: "Netlify Edge", symbol: "network", tint: .teal),
        BrandIcon(id: "workers", name: "Cloudflare Workers", symbol: "wrench.and.screwdriver.fill", tint: .orange),
        BrandIcon(id: "deno-deploy", name: "Deno Deploy", symbol: "tray.full.fill", tint: .blue),
        BrandIcon(id: "deno", name: "Deno", symbol: "tray.full.fill", tint: .blue),
        BrandIcon(id: "vercel", name: "Vercel", symbol: "triangle.fill", tint: .black),
        BrandIcon(id: "netlify", name: "Netlify", symbol: "network", tint: .teal),

        // MARK: Code & CI
        BrandIcon(id: "github", name: "GitHub", symbol: "chevron.left.forwardslash.chevron.right", tint: .white),
        BrandIcon(id: "gitlab", name: "GitLab", symbol: "flame.fill", tint: .orange),
        BrandIcon(id: "bitbucket", name: "Bitbucket", symbol: "circle.hexagongrid.fill", tint: .blue),
        BrandIcon(id: "git", name: "Git", symbol: "point.3.connected.trianglepath", tint: .orange),
        BrandIcon(id: "circleci", name: "CircleCI", symbol: "circle.circle.fill", tint: .teal),
        BrandIcon(id: "travis", name: "Travis CI", symbol: "tray.full.fill", tint: .green),
        BrandIcon(id: "github-actions", name: "GitHub Actions", symbol: "chevron.left.forwardslash.chevron.right", tint: .white),
        BrandIcon(id: "gitlab-ci", name: "GitLab CI", symbol: "flame.fill", tint: .orange),
        BrandIcon(id: "jenkins", name: "Jenkins", symbol: "person.and.background.dotted", tint: .red),
        BrandIcon(id: "buildkite", name: "Buildkite", symbol: "hammer.fill", tint: .purple),
        BrandIcon(id: "sentry", name: "Sentry", symbol: "exclamationmark.shield.fill", tint: .red),
        BrandIcon(id: "datadog", name: "Datadog", symbol: "chart.bar.xaxis", tint: .purple),
        BrandIcon(id: "new-relic", name: "New Relic", symbol: "chart.bar.xaxis", tint: .teal),

        // MARK: Package & Dependency
        BrandIcon(id: "npmjs", name: "npm", symbol: "cube.fill", tint: .red),
        BrandIcon(id: "pypi", name: "PyPI", symbol: "tray.full.fill", tint: .blue),
        BrandIcon(id: "crates", name: "crates.io", symbol: "square.and.arrow.up.on.square.fill", tint: .orange),
        BrandIcon(id: "rubygems", name: "RubyGems", symbol: "play.rectangle.fill", tint: .red),
        BrandIcon(id: "nuget", name: "NuGet", symbol: "square.grid.3x3.fill", tint: .blue),
        BrandIcon(id: "maven", name: "Maven Central", symbol: "tray.full.fill", tint: .purple),
        BrandIcon(id: "gradle", name: "Gradle", symbol: "square.and.arrow.up.on.square.fill", tint: .blue),

        // MARK: DNS & Domains
        BrandIcon(id: "cloudflare", name: "Cloudflare", symbol: "bolt.shield.fill", tint: .orange),
        BrandIcon(id: "cloudflare-dns", name: "Cloudflare DNS", symbol: "globe.americas.fill", tint: .orange),
        BrandIcon(id: "namecheap", name: "Namecheap", symbol: "globe.americas.fill", tint: .blue),
        BrandIcon(id: "godaddy", name: "GoDaddy", symbol: "globe.americas.fill", tint: .green),
        BrandIcon(id: "gandi", name: "Gandi", symbol: "globe.europe.fill", tint: .blue),
        BrandIcon(id: "hover", name: "Hover", symbol: "globe.americas.fill", tint: .teal),
        BrandIcon(id: "porkbun", name: "Porkbun", symbol: "globe.americas.fill", tint: .pink),
        BrandIcon(id: "dnsimple", name: "DNSimple", symbol: "globe.americas.fill", tint: .green),

        // MARK: General fallback icons
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
        BrandIcon(id: "cloud", name: "Cloud", symbol: "cloud.fill", tint: .blue),
        BrandIcon(id: "globe", name: "Globe", symbol: "globe.americas.fill", tint: .teal),
    ]

    /// Look up an icon by ID.
    static func find(id: String) -> BrandIcon? {
        library.first { $0.id == id }
    }

    /// Auto-detect the best icon for a given issuer name (case-insensitive).
    static func autodetect(for issuer: String) -> BrandIcon? {
        let lower = issuer.lowercased()
        let name = lower.replacingOccurrences(of: " ", with: "")

        // Exact contains matches
        if lower.contains("github") { return find(id: "github") }
        if lower.contains("gitlab") { return find(id: "gitlab") }
        if lower.contains("bitbucket") { return find(id: "bitbucket") }
        if lower.contains("cloudflare") { return find(id: "cloudflare") }
        if lower.contains("aws") || lower.contains("amazonwebservices") { return find(id: "aws") }
        if lower.contains("azure") { return find(id: "azure") }
        if lower.contains("gcp") || lower.contains("googlecloud") { return find(id: "gcp") }
        if lower.contains("digitalocean") || lower.contains("digital ocean") { return find(id: "digitalocean") }
        if lower.contains("heroku") { return find(id: "heroku") }
        if lower.contains("vercel") { return find(id: "vercel") }
        if lower.contains("netlify") { return find(id: "netlify") }
        if lower.contains("render") { return find(id: "render") }
        if lower.contains("fly.io") { return find(id: "flyio") }
        if lower.contains("railway") { return find(id: "railway") }
        if lower.contains("planetscale") { return find(id: "planetscale") }
        if lower.contains("supabase") { return find(id: "supabase") }
        if lower.contains("firebase") { return find(id: "firebase") }
        if lower.contains("notion") { return find(id: "notion") }
        if lower.contains("figma") { return find(id: "figma") }
        if lower.contains("linear") { return find(id: "linear") }
        if lower.contains("jira") { return find(id: "jira") }
        if lower.contains("trello") { return find(id: "trello") }
        if lower.contains("slack") { return find(id: "slack") }
        if lower.contains("discord") { return find(id: "discord") }
        if lower.contains("zoom") { return find(id: "zoom") }
        if lower.contains("teams") { return find(id: "teams") }
        if lower.contains("meet") && lower.contains("google") { return find(id: "meet") }
        if lower.contains("dropbox") { return find(id: "dropbox") }
        if lower.contains("box.com") { return find(id: "box") }
        if lower.contains("onedrive") { return find(id: "onedrive") }
        if lower.contains("google-drive") || lower.contains("drive.google.com") { return find(id: "googledrive") }
        if lower.contains("pcloud") { return find(id: "pcloud") }
        if lower.contains("proton") { return find(id: "proton") }
        if lower.contains("tutanota") || lower.contains("tuta.com") { return find(id: "tuta") }
        if lower.contains("fastmail") { return find(id: "fastmail") }
        if lower.contains("hey.com") { return find(id: "hey") }
        if lower.contains("gmail") { return find(id: "gmail") }
        if lower.contains("outlook") || lower.contains("hotmail") || lower.contains("live.com") { return find(id: "outlook") }
        if lower.contains("zoho") { return find(id: "zoho-mail") }
        if lower.contains("yandex") { return find(id: "yandex") }
        if lower.contains("mailfence") { return find(id: "mailfence") }
        if lower.contains("reddit") { return find(id: "reddit") }
        if lower.contains("stackoverflow") { return find(id: "stackoverflow") }
        if lower.contains("discourse") { return find(id: "discourse") }
        if lower.contains("phpbb") { return find(id: "phpbb") }
        if lower.contains("nodebb") { return find(id: "nodebb") }
        if lower.contains("patreon") { return find(id: "patreon") }
        if lower.contains("kofi") || lower.contains("ko-fi") { return find(id: "kofi") }
        if lower.contains("auth0") { return find(id: "auth0") }
        if lower.contains("okta") { return find(id: "okta") }
        if lower.contains("1password") || lower.contains("onepassword") { return find(id: "onepassword") }
        if lower.contains("bitwarden") { return find(id: "bitwarden") }
        if lower.contains("lastpass") { return find(id: "lastpass") }
        if lower.contains("dashlane") { return find(id: "dashlane") }
        if lower.contains("authy") { return find(id: "authy") }
        if lower.contains("duo") { return find(id: "duo") }
        if lower.contains("stripe") { return find(id: "stripe") }
        if lower.contains("paypal") { return find(id: "paypal") }
        if lower.contains("coinbase") { return find(id: "coinbase") }
        if lower.contains("binance") { return find(id: "binance") }
        if lower.contains("kraken") { return find(id: "kraken") }
        if lower.contains("gemini") { return find(id: "gemini") }
        if lower.contains("ledger") { return find(id: "ledger") }
        if lower.contains("trezor") { return find(id: "trezor") }
        if lower.contains("metamask") { return find(id: "metamask") }
        if lower.contains("wise") || lower.contains("transferwise") { return find(id: "wise") }
        if lower.contains("revolut") { return find(id: "revolut") }
        if lower.contains("steam") { return find(id: "steam") }
        if lower.contains("epicgames") || lower.contains("epicgames") { return find(id: "epic") }
        if lower.contains("riotgames") { return find(id: "riot") }
        if lower.contains("nintendo") { return find(id: "nintendo") }
        if lower.contains("playstation") || lower.contains("sony") { return find(id: "playstation") }
        if lower.contains("xbox") { return find(id: "xbox") }
        if lower.contains("battle.net") { return find(id: "battle.net") }
        if lower.contains("ubisoft") { return find(id: "ubisoft") }
        if lower.contains("rockstar") { return find(id: "rockstar") }
        if lower.contains("itch.io") { return find(id: "itch") }
        if lower.contains("circleci") { return find(id: "circleci") }
        if lower.contains("travis") { return find(id: "travis") }
        if lower.contains("githubactions") || lower.contains("github actions") { return find(id: "github-actions") }
        if lower.contains("jenkins") { return find(id: "jenkins") }
        if lower.contains("buildkite") { return find(id: "buildkite") }
        if lower.contains("sentry") { return find(id: "sentry") }
        if lower.contains("datadog") { return find(id: "datadog") }
        if lower.contains("new relic") { return find(id: "new-relic") }
        if lower.contains("namecheap") { return find(id: "namecheap") }
        if lower.contains("godaddy") { return find(id: "godaddy") }
        if lower.contains("gandi") { return find(id: "gandi") }
        if lower.contains("hover") { return find(id: "hover") }
        if lower.contains("porkbun") { return find(id: "porkbun") }
        if lower.contains("dnsimple") { return find(id: "dnsimple") }

        return nil
    }
}
