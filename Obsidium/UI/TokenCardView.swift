//
//  TokenCardView.swift
//  Obsidium
//
//  A token as a cryptographic "security card" where the code is the ONLY hero.
//  Issuer/label are quiet metadata; the only countdown is a small ring. On each
//  refresh the code resolves in with a subtle blur pulse (no utility-style bar).
//  Tap to copy (with haptic feedback).
//

import SwiftUI
import UIKit

struct TokenCardView: View {
    let account: Account
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date

    @State private var didCopy = false
    @State private var refreshBlur: CGFloat = 0

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
    private var showLabel: Bool { !account.label.isEmpty && account.displayTitle != account.label }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Header — issuer (metadata) + the lone countdown ring.
            HStack(alignment: .center, spacing: Theme.Spacing.sm) {
                Text(account.displayTitle)
                    .font(Theme.Typography.issuer)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: Theme.Spacing.sm)
                CountdownRing(progress: progress, secondsRemaining: secondsRemaining)
            }

            // Account label — quieter still; only when it adds information.
            if showLabel {
                Text(account.label)
                    .font(Theme.Typography.label)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            // Hero — the code. Pulled well clear of the metadata above it.
            Text(formattedCode)
                .font(Theme.Typography.code)
                .tracking(8)
                .foregroundStyle(didCopy ? Theme.accent : .primary)
                .contentTransition(.numericText())
                .animation(.snappy, value: code)
                .blur(radius: refreshBlur)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, Theme.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: code) { _, _ in pulseRefresh() }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
        .glassCard()
        .overlay { copiedBadge }
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .onTapGesture(perform: copyCode)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.displayTitle), code \(code)")
        .accessibilityHint("Double-tap to copy")
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

    /// Subtle "resolve into focus" shimmer when the code rolls over — the
    /// Apple-like replacement for a progress bar.
    private func pulseRefresh() {
        refreshBlur = 5
        withAnimation(.easeOut(duration: 0.5)) { refreshBlur = 0 }
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
