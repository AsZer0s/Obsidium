//
//  TokenCardView.swift
//  Obsidium
//
//  A token as a clean, Apple-style card inside the Wallet CardStack.
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
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date

    var mode: Mode = .detail
    /// Exact height set by the stack so the code row clips/reveals predictably.
    var height: CGFloat? = nil
    /// Pull the card out of the deck (header taps).
    var onTap: (() -> Void)? = nil

    @Environment(ToastCenter.self) private var toast
    @State private var didCopy = false

    private var code: String { TOTPGenerator.code(for: account, at: now) ?? "------" }
    private var hasCode: Bool { code != "------" }

    /// Group the code into two halves for readability, e.g. "652 087".
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
            // Fixed gap that keeps the code below the collapsed fold, so it's
            // clipped away until the card grows.
            Color.clear.frame(height: Theme.Spacing.xl)
            codeRow
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: height ?? 0, maxHeight: height, alignment: .topLeading)
        .background(cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .onTapGesture { mode == .header ? onTap?() : copyCode() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(mode == .header ? "Double-tap to reveal code" : "Double-tap to copy")
    }

    // MARK: Rows

    /// Issuer on the left, account name on the right — always visible.
    private var nameRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(account.displayTitle)
                .font(Theme.Typography.issuer)
                .foregroundStyle(.primary)
                .lineLimit(1)
            Spacer(minLength: Theme.Spacing.md)
            if hasLabel {
                Text(account.label)
                    .font(Theme.Typography.label)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    /// The code (hero) and the countdown ring — revealed as the card grows.
    private var codeRow: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            Text(formattedCode)
                .font(Theme.Typography.code)
                .tracking(4)
                .foregroundStyle(didCopy ? Theme.accent : .primary)
                .contentTransition(.numericText())
                .animation(.snappy, value: code)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: Theme.Spacing.sm)
            CountdownRing(progress: progress, secondsRemaining: secondsRemaining)
        }
    }

    // MARK: Surface

    /// Flat elevated card with a hairline rim and a subtle icon block in the
    /// top-left. (Shadow is applied by the body, after the content clip.)
    private var cardSurface: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        return shape
            .fill(Theme.card)
            .overlay(alignment: .topLeading) { watermark }
            .clipShape(shape)
            .overlay(shape.stroke(Theme.cardStroke, lineWidth: 1))
    }

    private var watermark: some View {
        Image(systemName: watermarkSymbol)
            .font(.system(size: 132, weight: .black))
            .foregroundStyle(.white.opacity(0.05))
            .offset(x: -50, y: -66)
            .allowsHitTesting(false)
    }

    private var watermarkSymbol: String {
        let symbols = [
            "lock.shield.fill", "key.fill", "bolt.shield.fill",
            "checkmark.shield.fill", "cube.fill", "hexagon.fill",
            "seal.fill", "cpu.fill",
        ]
        let key = account.issuer.isEmpty ? account.label : account.issuer
        let sum = key.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return symbols[sum % symbols.count]
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
