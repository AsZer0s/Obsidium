//
//  Theme.swift
//  Obsidium
//
//  Obsidium Design System v1. A small, HIG-aligned token layer: system
//  typography, a flat elevated dark card, and one calm accent. Dark-first,
//  minimal chrome, the code as the hero. No decorative gimmicks.
//

import SwiftUI

enum Theme {

    /// 4 / 8 / 12 / 16 / 24 / 32 spacing scale.
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 20
    }

    /// System type scale. SF for names, SF Mono for the code.
    enum Typography {
        static let code = Font.system(size: 44, weight: .regular, design: .monospaced)
        static let issuer = Font.headline                 // SF semibold
        static let label = Font.subheadline               // SF
    }

    // MARK: Palette (dark)

    /// Calm icy-blue accent — countdown, copy flash, actions.
    static let accent = Color(red: 0.40, green: 0.78, blue: 0.92)

    /// Soft amber for the expiring countdown (≤ 5s).
    static let warning = Color(red: 0.96, green: 0.58, blue: 0.40)

    /// Hairline rim for cards and chips.
    static let cardStroke = Color.white.opacity(0.09)

    /// Flat, gently elevated card surface.
    static let card = LinearGradient(
        colors: [
            Color(red: 0.160, green: 0.160, blue: 0.180),
            Color(red: 0.115, green: 0.115, blue: 0.130),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// App background — near-black.
    static let background = LinearGradient(
        colors: [
            Color(red: 0.050, green: 0.050, blue: 0.060),
            Color(red: 0.020, green: 0.020, blue: 0.030),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
