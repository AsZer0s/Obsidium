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
                codeRow
                    .padding(.top, Theme.Spacing.md)
                    .transition(.move(edge: .bottom))
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: height ?? 0, maxHeight: height, alignment: .topLeading)
        .background(
            ZStack {
                let shape = RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                shape.fill(Theme.card)
                shape.stroke(Theme.cardStroke, lineWidth: 1)
                watermark
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .onTapGesture { mode == .header ? onTap?() : copyCode() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(mode == .header ? "Double-tap to reveal code" : "Double-tap to copy")
    }

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

    private var selectedBrandIcon: BrandIcon {
        account.iconID.flatMap { BrandIcon.find(id: $0) }
            ?? BrandIcon.autodetect(for: account.issuer)
            ?? .default
    }

    private var watermark: some View {
        let icon = selectedBrandIcon
        return Image(systemName: icon.symbol)
            .font(.system(size: 132, weight: .black))
            .foregroundStyle(icon.tint?.opacity(0.06) ?? .white.opacity(0.05))
            .offset(x: -50, y: -66)
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
