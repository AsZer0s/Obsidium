//
//  TokenCardView.swift
//  Obsidium
//
//  A token rendered as a cryptographic "security card" where the code is the
//  only hero element. Issuer/label are demoted to metadata; the countdown is
//  a subtle chip + a thin draining bar. Tap to copy (with haptic feedback).
//

import SwiftUI
import UIKit

struct TokenCardView: View {
    let account: Account
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date

    @State private var didCopy = false

    private var code: String { TOTPGenerator.code(for: account, at: now) ?? "------" }
    private var hasCode: Bool { code != "------" }

    /// Group the code into two halves for readability, e.g. "792 874".
    private var formattedCode: String {
        guard hasCode, code.count == 6 || code.count == 8 else {
            return hasCode ? code : "— — —"
        }
        let mid = code.index(code.startIndex, offsetBy: code.count / 2)
        return "\(code[..<mid]) \(code[mid...])"
    }

    private var secondsRemaining: Int { TOTPGenerator.secondsRemaining(period: account.period, at: now) }
    private var progress: Double { TOTPGenerator.progress(period: account.period, at: now) }
    private var isExpiring: Bool { secondsRemaining <= 5 }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header — issuer (metadata) + demoted countdown.
            HStack(alignment: .firstTextBaseline) {
                Text(account.displayTitle)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: Theme.Spacing.sm)
                CountdownChip(progress: progress, secondsRemaining: secondsRemaining)
            }

            // Account label — demoted further; only when it adds information.
            if !account.label.isEmpty, account.displayTitle != account.label {
                Text(account.label)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            // Hero — the code. Everything else exists to support this line.
            Text(formattedCode)
                .font(.system(size: 42, weight: .semibold, design: .monospaced))
                .tracking(6)
                .foregroundStyle(didCopy ? Theme.accent : .primary)
                .contentTransition(.numericText())
                .animation(.snappy, value: code)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, Theme.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.Spacing.lg)
        .background(cardBackground)
        .overlay(alignment: .bottom) {
            CountdownBar(progress: progress, isExpiring: isExpiring)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.md)
        }
        .overlay { copiedBadge }
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .onTapGesture(perform: copyCode)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.displayTitle), code \(code)")
        .accessibilityHint("Double-tap to copy")
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
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
