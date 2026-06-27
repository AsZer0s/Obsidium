//
//  TokenCardView.swift
//  Obsidium
//
//  A token as a clean, Apple-style card inside the Wallet CardStack. Two modes:
//    .header  — collapsed: issuer on the left, account name on the right, so
//               several accounts from the same service stay distinguishable.
//    .detail  — pulled out: adds the big SF Mono code and the countdown ring.
//  Tapping a header pulls the card out (parent handles it); tapping a detail
//  card copies the code. A subtle icon block sits in the top-left.
//

import SwiftUI
import UIKit

struct TokenCardView: View {
    enum Mode { case header, detail }

    let account: Account
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date

    var mode: Mode = .detail
    /// Fixed height so the stack can overlap cards predictably.
    var height: CGFloat? = nil
    /// Pull the card out of the deck (header taps).
    var onTap: (() -> Void)? = nil

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
        Group {
            switch mode {
            case .header: headerContent
            case .detail: detailContent
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, mode == .header ? Theme.Spacing.md : Theme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: height ?? 0,
               alignment: mode == .header ? .leading : .topLeading)
        .background(card)
        .overlay { copiedBadge }
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .onTapGesture { mode == .header ? onTap?() : copyCode() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(mode == .header ? "Double-tap to reveal code" : "Double-tap to copy")
    }

    // MARK: Collapsed — issuer (left) + account name (right)

    private var headerContent: some View {
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
        .frame(maxWidth: .infinity)
    }

    // MARK: Pulled out — full card with the code

    private var detailContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
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
            .padding(.top, Theme.Spacing.xs)
        }
    }

    // MARK: Surface

    /// Flat elevated card with a hairline rim, a soft float, and a subtle
    /// icon block peeking from the top-left.
    private var card: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        return shape
            .fill(Theme.card)
            .overlay(alignment: .topLeading) { watermark }
            .clipShape(shape)
            .overlay(shape.stroke(Theme.cardStroke, lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
    }

    /// Oversized glyph pushed up-left so only its bottom-right peeks into the
    /// card's top-left. (SF Symbol stand-in; swap for a bundled FontAwesome glyph.)
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

    @ViewBuilder private var copiedBadge: some View {
        if didCopy {
            Text("Copied")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Theme.cardStroke, lineWidth: 1))
                .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
    }

    private var accessibilityText: String {
        mode == .header
            ? "\(account.displayTitle)\(hasLabel ? ", \(account.label)" : "")"
            : "\(account.displayTitle), code \(code)"
    }

    private func copyCode() {
        guard hasCode else { return }
        UIPasteboard.general.string = code
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.snappy) { didCopy = true }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.snappy) { didCopy = false }
        }
    }
}
