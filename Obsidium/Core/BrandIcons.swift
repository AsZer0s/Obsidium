//
//  BrandIcons.swift
//  Obsidium
//
//  FontAwesome-backed brand icons for MFA providers. The app stores only the
//  stable `id`; the visible mark is rendered from the bundled Font Awesome 7
//  OTF fonts. No SF Symbols are used for brand artwork.
//

import CoreText
import SwiftUI

/// One of the bundled Font Awesome font faces.
enum FontAwesomeStyle: String, Hashable {
    case brands
    case solid
    case regular

    var fontName: String {
        switch self {
        case .brands:
            return "FontAwesome7Brands-Regular"
        case .solid:
            return "FontAwesome7Free-Solid"
        case .regular:
            return "FontAwesome7Free-Regular"
        }
    }

    var fileName: String {
        switch self {
        case .brands:
            return "Font Awesome 7 Brands-Regular-400"
        case .solid:
            return "Font Awesome 7 Free-Solid-900"
        case .regular:
            return "Font Awesome 7 Free-Regular-400"
        }
    }
}

enum FontAwesome {
    private static var didRegister = false

    /// Register the bundled OTF fonts for this process. Calling more than once is harmless.
    static func registerFonts() {
        guard !didRegister else { return }
        didRegister = true
        for style in [FontAwesomeStyle.brands, .solid, .regular] {
            let fontURL = Bundle.main.url(forResource: style.fileName, withExtension: "otf")
                ?? Bundle.main.url(forResource: "Fonts/\(style.fileName)", withExtension: "otf")
                ?? Bundle.main.url(forResource: "otfs/\(style.fileName)", withExtension: "otf")
            guard let fontURL = fontURL else { continue }
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}

/// A FontAwesome icon descriptor with a stable ID, display name, glyph and tint.
struct BrandIcon: Identifiable, Hashable {
    let id: String
    let name: String
    let glyph: String
    let style: FontAwesomeStyle
    let tint: Color?
}

struct FontAwesomeIconView: View {
    let icon: BrandIcon
    var size: CGFloat

    var body: some View {
        Text(icon.glyph)
            .font(.custom(icon.style.fontName, size: size))
            .lineLimit(1)
            .minimumScaleFactor(0.2)
            .accessibilityLabel(icon.name)
    }
}

extension BrandIcon {
    /// Default icon if none selected.
    static let `default` = BrandIcon(id: "default", name: "Default", glyph: "\u{f023}", style: .solid, tint: Color(red: 0.40, green: 0.78, blue: 0.92))
}

extension BrandIcon {
    /// FontAwesome icon library. Brand entries use the Brands font; generic
    /// fallback entries use the Free Solid font so every icon still comes from
    /// FontAwesome.
    static let library: [BrandIcon] = [
        // MARK: Big Tech & Social
        BrandIcon(id: "github", name: "GitHub", glyph: "\u{f09b}", style: .brands, tint: .white),
        BrandIcon(id: "gitlab", name: "GitLab", glyph: "\u{f296}", style: .brands, tint: .orange),
        BrandIcon(id: "bitbucket", name: "Bitbucket", glyph: "\u{f171}", style: .brands, tint: .blue),
        BrandIcon(id: "google", name: "Google", glyph: "\u{f1a0}", style: .brands, tint: .blue),
        BrandIcon(id: "google-cloud", name: "Google Cloud", glyph: "\u{f0c2}", style: .solid, tint: .blue),
        BrandIcon(id: "gmail", name: "Gmail", glyph: "\u{f0e0}", style: .solid, tint: .red),
        BrandIcon(id: "microsoft", name: "Microsoft", glyph: "\u{f3ca}", style: .brands, tint: .blue),
        BrandIcon(id: "outlook", name: "Outlook", glyph: "\u{f0e0}", style: .solid, tint: .blue),
        BrandIcon(id: "azure", name: "Azure", glyph: "\u{f0c2}", style: .solid, tint: .blue),
        BrandIcon(id: "apple", name: "Apple", glyph: "\u{f179}", style: .brands, tint: .black),
        BrandIcon(id: "apple-id", name: "Apple ID", glyph: "\u{f179}", style: .brands, tint: .black),
        BrandIcon(id: "icloud", name: "iCloud", glyph: "\u{f0c2}", style: .solid, tint: .blue),
        BrandIcon(id: "facebook", name: "Facebook", glyph: "\u{f09a}", style: .brands, tint: .blue),
        BrandIcon(id: "instagram", name: "Instagram", glyph: "\u{f16d}", style: .brands, tint: .purple),
        BrandIcon(id: "whatsapp", name: "WhatsApp", glyph: "\u{f232}", style: .brands, tint: .green),
        BrandIcon(id: "telegram", name: "Telegram", glyph: "\u{f2c6}", style: .brands, tint: .blue),
        BrandIcon(id: "discord", name: "Discord", glyph: "\u{f392}", style: .brands, tint: .purple),
        BrandIcon(id: "slack", name: "Slack", glyph: "\u{f198}", style: .brands, tint: .purple),
        BrandIcon(id: "twitter", name: "X / Twitter", glyph: "\u{e61f}", style: .brands, tint: .black),
        BrandIcon(id: "x-twitter", name: "X / Twitter", glyph: "\u{e61f}", style: .brands, tint: .black),
        BrandIcon(id: "linkedin", name: "LinkedIn", glyph: "\u{f08c}", style: .brands, tint: .blue),
        BrandIcon(id: "reddit", name: "Reddit", glyph: "\u{f1a1}", style: .brands, tint: .orange),
        BrandIcon(id: "tiktok", name: "TikTok", glyph: "\u{e07b}", style: .brands, tint: .black),
        BrandIcon(id: "youtube", name: "YouTube", glyph: "\u{f167}", style: .brands, tint: .red),
        BrandIcon(id: "twitch", name: "Twitch", glyph: "\u{f1e8}", style: .brands, tint: .purple),
        BrandIcon(id: "amazon", name: "Amazon", glyph: "\u{f270}", style: .brands, tint: .orange),
        BrandIcon(id: "aws", name: "AWS", glyph: "\u{f375}", style: .brands, tint: .orange),
        BrandIcon(id: "amazon-aws", name: "AWS", glyph: "\u{f375}", style: .brands, tint: .orange),

        // MARK: Chinese Mainland Providers & Apps
        BrandIcon(id: "aliyun", name: "阿里云", glyph: "\u{f0c2}", style: .solid, tint: .orange),
        BrandIcon(id: "alicloud", name: "阿里云", glyph: "\u{f0c2}", style: .solid, tint: .orange),
        BrandIcon(id: "tencent-cloud", name: "腾讯云", glyph: "\u{f0c2}", style: .solid, tint: .blue),
        BrandIcon(id: "tencentcloud", name: "腾讯云", glyph: "\u{f0c2}", style: .solid, tint: .blue),
        BrandIcon(id: "huawei-cloud", name: "华为云", glyph: "\u{f0c2}", style: .solid, tint: .red),
        BrandIcon(id: "huaweicloud", name: "华为云", glyph: "\u{f0c2}", style: .solid, tint: .red),
        BrandIcon(id: "wechat", name: "微信", glyph: "\u{f1d7}", style: .brands, tint: .green),
        BrandIcon(id: "weixin", name: "微信", glyph: "\u{f1d7}", style: .brands, tint: .green),
        BrandIcon(id: "alipay", name: "支付宝", glyph: "\u{f642}", style: .brands, tint: .blue),
        BrandIcon(id: "zhifubao", name: "支付宝", glyph: "\u{f642}", style: .brands, tint: .blue),
        BrandIcon(id: "qq", name: "QQ", glyph: "\u{f1d6}", style: .brands, tint: .teal),
        BrandIcon(id: "weibo", name: "微博", glyph: "\u{f18a}", style: .brands, tint: .red),
        BrandIcon(id: "sina-weibo", name: "新浪微博", glyph: "\u{f18a}", style: .brands, tint: .red),
        BrandIcon(id: "taobao", name: "淘宝", glyph: "\u{f07a}", style: .solid, tint: .orange),
        BrandIcon(id: "tmall", name: "天猫", glyph: "\u{f07a}", style: .solid, tint: .red),
        BrandIcon(id: "jd", name: "京东", glyph: "\u{f07a}", style: .solid, tint: .red),
        BrandIcon(id: "pinduoduo", name: "拼多多", glyph: "\u{f07a}", style: .solid, tint: .orange),
        BrandIcon(id: "bilibili", name: "哔哩哔哩", glyph: "\u{f26c}", style: .solid, tint: .pink),
        BrandIcon(id: "bzhan", name: "哔哩哔哩", glyph: "\u{f26c}", style: .solid, tint: .pink),
        BrandIcon(id: "douyin", name: "抖音", glyph: "\u{e07b}", style: .brands, tint: .red),
        BrandIcon(id: "tiktok-cn", name: "抖音", glyph: "\u{e07b}", style: .brands, tint: .red),
        BrandIcon(id: "kuaishou", name: "快手", glyph: "\u{f030}", style: .solid, tint: .orange),
        BrandIcon(id: "zhihu", name: "知乎", glyph: "\u{f63f}", style: .brands, tint: .blue),
        BrandIcon(id: "dingtalk", name: "钉钉", glyph: "\u{f0b1}", style: .solid, tint: .blue),
        BrandIcon(id: "feishu", name: "飞书", glyph: "\u{f0b1}", style: .solid, tint: .blue),
        BrandIcon(id: "lark", name: "飞书", glyph: "\u{f0b1}", style: .solid, tint: .blue),
        BrandIcon(id: "netease", name: "网易", glyph: "\u{f001}", style: .solid, tint: .red),
        BrandIcon(id: "163", name: "网易邮箱", glyph: "\u{f0e0}", style: .solid, tint: .red),
        BrandIcon(id: "126mail", name: "126邮箱", glyph: "\u{f0e0}", style: .solid, tint: .red),
        BrandIcon(id: "189mail", name: "189邮箱", glyph: "\u{f0e0}", style: .solid, tint: .teal),
        BrandIcon(id: "baidu", name: "百度", glyph: "\u{f002}", style: .solid, tint: .blue),
        BrandIcon(id: "baidu-cloud", name: "百度云", glyph: "\u{f0c2}", style: .solid, tint: .blue),

        // MARK: Cloud / Dev Tools / SaaS
        BrandIcon(id: "cloudflare", name: "Cloudflare", glyph: "\u{e07d}", style: .brands, tint: .orange),
        BrandIcon(id: "vercel", name: "Vercel", glyph: "\u{f04b}", style: .solid, tint: .black),
        BrandIcon(id: "netlify", name: "Netlify", glyph: "\u{f0e8}", style: .solid, tint: .teal),
        BrandIcon(id: "heroku", name: "Heroku", glyph: "\u{f0c2}", style: .solid, tint: .purple),
        BrandIcon(id: "digitalocean", name: "DigitalOcean", glyph: "\u{f391}", style: .brands, tint: .blue),
        BrandIcon(id: "linode", name: "Linode", glyph: "\u{f233}", style: .solid, tint: .blue),
        BrandIcon(id: "docker", name: "Docker", glyph: "\u{f395}", style: .brands, tint: .blue),
        BrandIcon(id: "notion", name: "Notion", glyph: "\u{f15c}", style: .solid, tint: .black),
        BrandIcon(id: "figma", name: "Figma", glyph: "\u{f799}", style: .brands, tint: .purple),
        BrandIcon(id: "linear", name: "Linear", glyph: "\u{f058}", style: .solid, tint: .purple),
        BrandIcon(id: "asana", name: "Asana", glyph: "\u{f058}", style: .solid, tint: .red),
        BrandIcon(id: "jira", name: "Jira", glyph: "\u{f7b1}", style: .brands, tint: .blue),
        BrandIcon(id: "trello", name: "Trello", glyph: "\u{f181}", style: .brands, tint: .blue),
        BrandIcon(id: "zoom", name: "Zoom", glyph: "\u{f03d}", style: .solid, tint: .blue),
        BrandIcon(id: "teams", name: "Microsoft Teams", glyph: "\u{f3ca}", style: .brands, tint: .purple),
        BrandIcon(id: "meet", name: "Google Meet", glyph: "\u{f03d}", style: .solid, tint: .green),
        BrandIcon(id: "dropbox", name: "Dropbox", glyph: "\u{f16b}", style: .brands, tint: .blue),
        BrandIcon(id: "onedrive", name: "OneDrive", glyph: "\u{f0c2}", style: .solid, tint: .blue),
        BrandIcon(id: "googledrive", name: "Google Drive", glyph: "\u{f3aa}", style: .brands, tint: .green),
        BrandIcon(id: "proton", name: "ProtonMail", glyph: "\u{f0e0}", style: .solid, tint: .purple),
        BrandIcon(id: "protonmail", name: "ProtonMail", glyph: "\u{f0e0}", style: .solid, tint: .purple),
        BrandIcon(id: "stackoverflow", name: "Stack Overflow", glyph: "\u{f16c}", style: .brands, tint: .orange),

        // MARK: Security / Finance / Gaming
        BrandIcon(id: "auth0", name: "Auth0", glyph: "\u{f3ed}", style: .solid, tint: .orange),
        BrandIcon(id: "okta", name: "Okta", glyph: "\u{f084}", style: .solid, tint: .blue),
        BrandIcon(id: "onepassword", name: "1Password", glyph: "\u{f084}", style: .solid, tint: .blue),
        BrandIcon(id: "bitwarden", name: "Bitwarden", glyph: "\u{f3ed}", style: .solid, tint: .blue),
        BrandIcon(id: "lastpass", name: "LastPass", glyph: "\u{f084}", style: .solid, tint: .red),
        BrandIcon(id: "stripe", name: "Stripe", glyph: "\u{f429}", style: .brands, tint: .indigo),
        BrandIcon(id: "paypal", name: "PayPal", glyph: "\u{f1ed}", style: .brands, tint: .blue),
        BrandIcon(id: "coinbase", name: "Coinbase", glyph: "\u{f379}", style: .brands, tint: .blue),
        BrandIcon(id: "bitcoin", name: "Bitcoin", glyph: "\u{f379}", style: .brands, tint: .orange),
        BrandIcon(id: "ethereum", name: "Ethereum", glyph: "\u{f42e}", style: .brands, tint: .purple),
        BrandIcon(id: "steam", name: "Steam", glyph: "\u{f1b6}", style: .brands, tint: .black),
        BrandIcon(id: "epic", name: "Epic Games", glyph: "\u{f11b}", style: .solid, tint: .white),
        BrandIcon(id: "riot", name: "Riot Games", glyph: "\u{f06d}", style: .solid, tint: .red),
        BrandIcon(id: "nintendo", name: "Nintendo", glyph: "\u{f11b}", style: .solid, tint: .red),
        BrandIcon(id: "playstation", name: "PlayStation", glyph: "\u{f3df}", style: .brands, tint: .blue),
        BrandIcon(id: "xbox", name: "Xbox", glyph: "\u{f412}", style: .brands, tint: .green),

        // MARK: Code / Platforms / General
        BrandIcon(id: "git", name: "Git", glyph: "\u{f1d3}", style: .brands, tint: .orange),
        BrandIcon(id: "npmjs", name: "npm", glyph: "\u{f3d4}", style: .brands, tint: .red),
        BrandIcon(id: "python", name: "Python", glyph: "\u{f3e2}", style: .brands, tint: .blue),
        BrandIcon(id: "java", name: "Java", glyph: "\u{f4e4}", style: .brands, tint: .red),
        BrandIcon(id: "swift", name: "Swift", glyph: "\u{f8e1}", style: .brands, tint: .orange),
        BrandIcon(id: "react", name: "React", glyph: "\u{f41b}", style: .brands, tint: .cyan),
        BrandIcon(id: "vuejs", name: "Vue.js", glyph: "\u{f41f}", style: .brands, tint: .green),
        BrandIcon(id: "angular", name: "Angular", glyph: "\u{f420}", style: .brands, tint: .red),
        BrandIcon(id: "linux", name: "Linux", glyph: "\u{f17c}", style: .brands, tint: .yellow),
        BrandIcon(id: "windows", name: "Windows", glyph: "\u{f17a}", style: .brands, tint: .blue),
        BrandIcon(id: "android", name: "Android", glyph: "\u{f17b}", style: .brands, tint: .green),
        BrandIcon(id: "wordpress", name: "WordPress", glyph: "\u{f19a}", style: .brands, tint: .blue),
        BrandIcon(id: "shield", name: "Shield", glyph: "\u{f3ed}", style: .solid, tint: Color(red: 0.40, green: 0.78, blue: 0.92)),
        BrandIcon(id: "key", name: "Key", glyph: "\u{f084}", style: .solid, tint: .orange),
        BrandIcon(id: "lock", name: "Lock", glyph: "\u{f023}", style: .solid, tint: .gray),
        BrandIcon(id: "star", name: "Star", glyph: "\u{f005}", style: .solid, tint: .yellow),
        BrandIcon(id: "bolt", name: "Bolt", glyph: "\u{f0e7}", style: .solid, tint: .orange),
        BrandIcon(id: "leaf", name: "Leaf", glyph: "\u{f06c}", style: .solid, tint: .green),
        BrandIcon(id: "heart", name: "Heart", glyph: "\u{f004}", style: .solid, tint: .red),
        BrandIcon(id: "cloud", name: "Cloud", glyph: "\u{f0c2}", style: .solid, tint: .blue),
        BrandIcon(id: "globe", name: "Globe", glyph: "\u{f0ac}", style: .solid, tint: .teal),
    ]

    /// Look up an icon by ID.
    static func find(id: String) -> BrandIcon? {
        library.first { $0.id == id }
    }

    /// Auto-detect the best icon for a given issuer name (case-insensitive).
    static func autodetect(for issuer: String) -> BrandIcon? {
        let lower = issuer.lowercased()
        let name = lower.replacingOccurrences(of: " ", with: "")

        if lower.contains("github") { return find(id: "github") }
        if lower.contains("gitlab") { return find(id: "gitlab") }
        if lower.contains("bitbucket") { return find(id: "bitbucket") }
        if lower.contains("cloudflare") { return find(id: "cloudflare") }
        if lower.contains("aws") || lower.contains("amazonwebservices") { return find(id: "aws") }
        if lower.contains("azure") { return find(id: "azure") }
        if lower.contains("gcp") || lower.contains("googlecloud") { return find(id: "google-cloud") }
        if lower.contains("digitalocean") || lower.contains("digital ocean") { return find(id: "digitalocean") }
        if lower.contains("docker") { return find(id: "docker") }
        if lower.contains("heroku") { return find(id: "heroku") }
        if lower.contains("vercel") { return find(id: "vercel") }
        if lower.contains("netlify") { return find(id: "netlify") }
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
        if lower.contains("onedrive") { return find(id: "onedrive") }
        if lower.contains("google-drive") || lower.contains("drive.google.com") { return find(id: "googledrive") }
        if lower.contains("proton") { return find(id: "proton") }
        if lower.contains("gmail") { return find(id: "gmail") }
        if lower.contains("outlook") || lower.contains("hotmail") || lower.contains("live.com") { return find(id: "outlook") }
        if lower.contains("reddit") { return find(id: "reddit") }
        if lower.contains("stackoverflow") { return find(id: "stackoverflow") }
        if lower.contains("auth0") { return find(id: "auth0") }
        if lower.contains("okta") { return find(id: "okta") }
        if lower.contains("1password") || lower.contains("onepassword") { return find(id: "onepassword") }
        if lower.contains("bitwarden") { return find(id: "bitwarden") }
        if lower.contains("lastpass") { return find(id: "lastpass") }
        if lower.contains("stripe") { return find(id: "stripe") }
        if lower.contains("paypal") { return find(id: "paypal") }
        if lower.contains("coinbase") { return find(id: "coinbase") }
        if lower.contains("bitcoin") { return find(id: "bitcoin") }
        if lower.contains("ethereum") { return find(id: "ethereum") }
        if lower.contains("steam") { return find(id: "steam") }
        if lower.contains("epicgames") || lower.contains("epic games") { return find(id: "epic") }
        if lower.contains("riotgames") || lower.contains("riot games") { return find(id: "riot") }
        if lower.contains("nintendo") { return find(id: "nintendo") }
        if lower.contains("playstation") || lower.contains("sony") { return find(id: "playstation") }
        if lower.contains("xbox") { return find(id: "xbox") }
        if lower.contains("youtube") { return find(id: "youtube") }
        if lower.contains("twitch") { return find(id: "twitch") }
        if lower.contains("telegram") { return find(id: "telegram") }
        if lower.contains("whatsapp") { return find(id: "whatsapp") }
        if lower.contains("instagram") { return find(id: "instagram") }
        if lower.contains("facebook") { return find(id: "facebook") }
        if lower.contains("linkedin") { return find(id: "linkedin") }
        if lower.contains("tiktok") { return find(id: "tiktok") }
        if lower.contains("twitter") || lower.contains("x.com") { return find(id: "x-twitter") }
        if lower.contains("google") { return find(id: "google") }
        if lower.contains("microsoft") { return find(id: "microsoft") }
        if lower.contains("apple") { return find(id: "apple") }
        if lower.contains("icloud") { return find(id: "icloud") }
        if lower.contains("npm") { return find(id: "npmjs") }
        if lower.contains("python") { return find(id: "python") }
        if lower.contains("java") { return find(id: "java") }
        if lower.contains("swift") { return find(id: "swift") }
        if lower.contains("react") { return find(id: "react") }
        if lower.contains("vue") { return find(id: "vuejs") }
        if lower.contains("angular") { return find(id: "angular") }
        if lower.contains("linux") { return find(id: "linux") }
        if lower.contains("windows") { return find(id: "windows") }
        if lower.contains("android") { return find(id: "android") }
        if lower.contains("wordpress") { return find(id: "wordpress") }

        // Chinese Mainland providers and apps.
        if lower.contains("aliyun") || lower.contains("alicloud") || lower.contains("aliyun.com") { return find(id: "aliyun") }
        if lower.contains("tencent") || lower.contains("qcloud") || lower.contains("tencentcloud") { return find(id: "tencent-cloud") }
        if lower.contains("huawei") || lower.contains("huaweicloud") { return find(id: "huawei-cloud") }
        if lower.contains("wechat") || lower.contains("weixin") { return find(id: "wechat") }
        if lower.contains("alipay") || lower.contains("zhifubao") { return find(id: "alipay") }
        if lower.contains("qq.com") || lower.contains("qqmail") || name == "qq" { return find(id: "qq") }
        if lower.contains("weibo") || lower.contains("sina") { return find(id: "weibo") }
        if lower.contains("taobao") { return find(id: "taobao") }
        if lower.contains("tmall") { return find(id: "tmall") }
        if lower.contains("jd.com") || lower.contains("jingdong") { return find(id: "jd") }
        if lower.contains("pinduoduo") || lower.contains("pdd") { return find(id: "pinduoduo") }
        if lower.contains("bilibili") || lower.contains("bzhan") { return find(id: "bilibili") }
        if lower.contains("douyin") { return find(id: "douyin") }
        if lower.contains("kuaishou") { return find(id: "kuaishou") }
        if lower.contains("zhihu") { return find(id: "zhihu") }
        if lower.contains("dingtalk") { return find(id: "dingtalk") }
        if lower.contains("feishu") || lower.contains("lark") { return find(id: "feishu") }
        if lower.contains("netease") || lower.contains("163.com") { return find(id: "netease") }
        if lower.contains("126.com") { return find(id: "126mail") }
        if lower.contains("189.com") { return find(id: "189mail") }
        if lower.contains("baidu") { return find(id: "baidu") }

        return nil
    }
}
