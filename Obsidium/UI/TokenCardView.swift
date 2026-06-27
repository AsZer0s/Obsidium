//
//  TokenCardView.swift
//  Obsidium
//
//  A token as a polished obsidian slab. The code is engraved into the surface
//  (the only hero); the issuer is a small serif nameplate and the account a dim
//  machine handle. A spectral light streaks the top edge. Used both as a
//  free-standing card and as a member of the Wallet-style CardStack.
//
//  - When `stacked` is true a tap expands the deck (handled by the parent);
//    otherwise a tap copies the code.
//

import SwiftUI
import UIKit

struct TokenCardView: View {
    let account: Account
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date

    /// Fixed height for predictable overlap inside the stack (nil = intrinsic).
    var height: CGFloat? = nil
    /// In the collapsed deck a tap expands rather than copies.
    var stacked: Bool = false
    var onStackTap: (() -> Void)? = nil

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
            // Nameplate row — serif issuer + the lone countdown ring.
            HStack(alignment: .center, spacing: Theme.Spacing.sm) {
                Text(account.displayTitle)
                    .font(Theme.Typography.issuer)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                Spacer(minLength: Theme.Spacing.sm)
                CountdownRing(progress: progress, secondsRemaining: secondsRemaining)
            }

            // Machine handle — quiet, monospaced; only when it adds information.
            if showLabel {
                Text(account.label)
                    .font(Theme.Typography.label)
                    .foregroundStyle(.white.opacity(0.42))
                    .lineLimit(1)
            }

            // Hero — the code, engraved into the slab.
            Text(formattedCode)
                .font(Theme.Typography.code)
                .tracking(6)
                .foregroundStyle(didCopy ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.codeFill))
                .shadow(color: .black.opacity(0.55), radius: 0, y: 1)   // emboss: carved into glass
                .contentTransition(.numericText())
                .animation(.snappy, value: code)
                .blur(radius: refreshBlur)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: code) { _, _ in pulseRefresh() }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: height ?? 0, alignment: .topLeading)
        .background(slab)
        .overlay { copiedBadge }
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .onTapGesture { stacked ? onStackTap?() : copyCode() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.displayTitle), code \(code)")
        .accessibilityHint(stacked ? "Double-tap to expand" : "Double-tap to copy")
    }

    /// The polished obsidian surface: a background icon block, stone gradient,
    /// hairline rim, a spectral light across the top edge, and a soft float.
    private var slab: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        return shape
            .fill(Theme.slab)
            .overlay(alignment: .topLeading) { watermark }
            .clipShape(shape)
            .overlay(shape.stroke(Theme.cardStroke, lineWidth: 1))
            .overlay(alignment: .top) {
                Theme.sheenLine
                    .frame(height: 1)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, 1)
            }
            .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
    }

    /// An oversized glyph as a background block — pushed up-left so only its
    /// bottom-right corner peeks into the card's top-left. (SF Symbol stand-in;
    /// swap for a bundled FontAwesome glyph to use brand marks.)
    private var watermark: some View {
        Image(systemName: watermarkSymbol)
            .font(.system(size: 150, weight: .black))
            .foregroundStyle(Theme.accent.opacity(0.08))
            .offset(x: -58, y: -78)
            .allowsHitTesting(false)
    }

    /// Deterministic per-issuer pick so each account keeps a stable motif.
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

    /// Brief "re-etch into focus" when the code rolls over.
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
