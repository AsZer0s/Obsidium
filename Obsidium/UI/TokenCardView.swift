//
//  TokenCardView.swift
//  Obsidium
//
//  A token as a clean, Apple Wallet–style card inside the CardStack.
//
//  Each card wears its brand's colour: a rich, deep gradient derived from the
//  brand tint, a crisp logo chip in the top-left, and a large faint glyph
//  watermark — the signature Wallet "pass" look. Text is always high-contrast
//  white so it reads on any colour.
//
//  The card has ONE stable content tree — the name/username row plus the code
//  row are always present. Collapsed, the card is short and the code row is
//  clipped away below the fold; pulled out, the card grows and the clip wipes
//  the code into view. Because nothing is swapped, expanding is a real
//  slide-and-grow, never a crossfade.
//
//  `mode` only governs tap behaviour (header → pull out, detail → copy) and
//  the accessibility label. Copying raises an app-level toast + haptic.
//

import SwiftUI
import UIKit

struct TokenCardView: View {
    enum Mode { case header, detail }

    let account: Account
    let now: Date
    var mode: Mode = .detail
    var height: CGFloat? = nil
    var onTap: (() -> Void)? = nil

    @Environment(ToastCenter.self) private var toast
    @State private var didCopy = false

    private var code: String { TOTPGenerator.code(for: account, at: now) ?? "------" }
    private var hasCode: Bool { code != "------" }

    private var formattedCode: String {
        guard hasCode, code.count == 6 || code.count == 8 else {
            return hasCode ? code : "— — —"
        }
        let mid = code.index(code.startIndex, offsetBy: code.count / 2)
        return "\(code[..<mid]) \(code[mid...])"
    }

    private var secondsRemaining: Int { TOTPGenerator.secondsRemaining(period: account.period, at: now) }
    private var progress: Double { TOTPGenerator.progress(period: account.period, at: now) }
    private var hasLabel: Bool { !account.label.isEmpty && account.displayTitle != account.label }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            nameRow
            if mode == .detail {
                Spacer(minLength: Theme.Spacing.md)
                codeRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: height ?? 0, maxHeight: height, alignment: .topLeading)
        .background(cardTint)
        .glassEffect(.regular.tint(brandTint.opacity(0.55)).interactive(), in: cardShape)
        .overlay(cardShape.stroke(.white.opacity(0.18), lineWidth: 1))
        .shadow(color: brandTint.opacity(0.28), radius: 16, y: 8)
        .shadow(color: .black.opacity(0.30), radius: 6, y: 3)
        .contentShape(cardShape)
        .onTapGesture { mode == .header ? onTap?() : copyCode() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(mode == .header ? "Double-tap to reveal code" : "Double-tap to copy")
    }

    // MARK: Rows

    private var nameRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(account.displayTitle)
                .font(Theme.Typography.issuer)
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer(minLength: Theme.Spacing.md)
            if hasLabel {
                Text(account.label)
                    .font(Theme.Typography.label)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var codeRow: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            Text(formattedCode)
                .font(Theme.Typography.code)
                .tracking(4)
                .foregroundStyle(didCopy ? .white : .white.opacity(0.95))
                .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                .contentTransition(.numericText())
                .animation(.snappy, value: code)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: Theme.Spacing.sm)
            CountdownRing(progress: progress, secondsRemaining: secondsRemaining, tint: .white)
        }
    }

    // MARK: Background

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
    }

    private var selectedBrandIcon: BrandIcon {
        account.iconID.flatMap { BrandIcon.find(id: $0) }
            ?? BrandIcon.autodetect(for: account.issuer)
            ?? .default
    }

    /// The brand's base colour, lifted off pure black so the tint can read.
    private var brandTint: Color {
        let tint = selectedBrandIcon.tint ?? Theme.accent
        return tint.brightness < 0.10 ? Color(white: 0.28) : tint
    }

    /// Translucent layers painted over the Liquid Glass: a faint brand-colour
    /// wash for identity, the big brand glyph, and a top sheen. Everything is
    /// low-opacity so the dark backdrop keeps showing through the glass.
    private var cardTint: some View {
        let tint = brandTint
        return ZStack {
            LinearGradient(
                colors: [tint.opacity(0.32), tint.opacity(0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Big faint brand glyph, bleeding off the bottom-right corner.
            Image(systemName: selectedBrandIcon.symbol)
                .font(.system(size: 150, weight: .black))
                .foregroundStyle(.white.opacity(0.10))
                .rotationEffect(.degrees(-12))
                .offset(x: 70, y: 36)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            // Soft top sheen for a glossy finish.
            LinearGradient(
                colors: [.white.opacity(0.18), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .blendMode(.overlay)
        }
        .clipShape(cardShape)
        .allowsHitTesting(false)
    }

    private var accessibilityText: String {
        mode == .header
            ? "\(account.displayTitle)\(hasLabel ? ", \(account.label)" : "")"
            : "\(account.displayTitle), code \(code)"
    }

    private func copyCode() {
        guard hasCode else { return }
        UIPasteboard.general.string = code
        Haptics.copy()
        toast.show("Code copied")
        withAnimation(.snappy) { didCopy = true }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.snappy) { didCopy = false }
        }
    }
}

// MARK: - Colour helpers

private extension Color {
    /// Perceived brightness (0...1) via the standard luma weighting.
    var brightness: CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b
    }
}
