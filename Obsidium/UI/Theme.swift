//
//  Theme.swift
//  Obsidium
//
//  Obsidium Design System v1 — obsidian edition. A small token layer so every
//  surface stays consistent. Visual language: polished volcanic glass, a single
//  spectral cut-edge, security-grade air, and an engraved monospaced code as the
//  identity. The code is always the only hero.
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
        static let card: CGFloat = 18
        static let chamfer: CGFloat = 24
    }

    /// Type scale. The code dominates; the rest reads as the artifact's label.
    enum Typography {
        /// The hero — engraved into the glass.
        static let code = Font.system(size: 46, weight: .medium, design: .monospaced)
        /// Service name — a small serif nameplate.
        static let issuer = Font.system(.footnote, design: .serif).weight(.medium)
        /// Account handle — the raw machine string.
        static let label = Font.system(.caption2, design: .monospaced)
    }

    // MARK: Obsidian palette

    /// Deepest background — the void the slabs float in.
    static let ink = Color(red: 0.02, green: 0.02, blue: 0.03)

    /// Polished-stone surface gradient (light catches the top-left).
    static let slab = LinearGradient(
        colors: [
            Color(red: 0.086, green: 0.090, blue: 0.110),  // #16171C
            Color(red: 0.039, green: 0.043, blue: 0.055),  // #0A0B0E
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Spectral sheen that traces the cut facet — obsidian's rainbow edge.
    static let sheen = LinearGradient(
        colors: [
            Color(red: 0.49, green: 0.55, blue: 1.00),     // cool violet
            Color(red: 0.36, green: 0.88, blue: 0.84),     // cyan
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Engraved code fill — polished white cooling toward the base.
    static let codeFill = LinearGradient(
        colors: [Color.white, Color(red: 0.79, green: 0.83, blue: 0.90)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Glacial spectral accent (copy flash, actions, fresh countdown).
    static let accent = Color(red: 0.48, green: 0.80, blue: 0.94)

    /// Ember — the countdown warming as the step cools to expiry.
    static let warning = Color(red: 0.91, green: 0.69, blue: 0.35)

    /// Hairline rim for slabs and chips.
    static let cardStroke = Color.white.opacity(0.07)

    /// App background — deep obsidian void.
    static let background = LinearGradient(
        colors: [
            Color(red: 0.039, green: 0.041, blue: 0.051),
            Color(red: 0.016, green: 0.016, blue: 0.024),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
