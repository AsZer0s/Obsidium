//
//  Theme.swift
//  Obsidium
//
//  A small, deliberately minimal design-token layer so the UI stays
//  consistent. Obsidium's visual language: dark-first, minimal chrome,
//  security-grade spacing, monospaced digits as the identity.
//

import SwiftUI

enum Theme {

    /// 4 / 8 / 12 / 16 / 24 spacing scale.
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 20
    }

    // MARK: Dark security palette

    /// Calm, desaturated mint — reads as "secure" without shouting.
    static let accent = Color(red: 0.40, green: 0.82, blue: 0.70)

    /// Soft coral for the expiring state (kinder than pure red on dark).
    static let warning = Color(red: 0.96, green: 0.50, blue: 0.45)

    /// Hairline border for glass cards.
    static let cardStroke = Color.white.opacity(0.08)

    /// App background — near-black obsidian gradient with a faint cool tint.
    static let background = LinearGradient(
        colors: [
            Color(red: 0.07, green: 0.075, blue: 0.09),
            Color(red: 0.03, green: 0.03, blue: 0.045),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
