//
//  Theme.swift
//  Obsidium
//
//  Obsidium Design System v1. A deliberately small token layer — spacing,
//  type scale, color, and one card style — so every surface stays consistent.
//  Visual language: dark-first, minimal chrome, security-grade air, and
//  monospaced digits as the identity. The code is always the only hero.
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
        static let card: CGFloat = 22
    }

    /// Type scale. The code dominates; everything else reads as metadata.
    enum Typography {
        /// The hero — the only thing you should notice at a glance.
        static let code = Font.system(size: 48, weight: .semibold, design: .monospaced)
        /// Service name — quiet metadata.
        static let issuer = Font.caption
        /// Account label — quieter still.
        static let label = Font.caption2
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

// MARK: - Card style

extension View {
    /// The Obsidium glass card: translucent material, hairline border, soft
    /// float. The single reusable surface treatment in the design system.
    func glassCard(cornerRadius: CGFloat = Theme.Radius.card) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Theme.cardStroke, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.28), radius: 10, y: 5)
        )
    }
}
