//
//  TokenCardView.swift
//  Obsidium
//
//  A token as a slab of cut obsidian. The code is engraved into the polished
//  surface (the only hero); the issuer is a small serif nameplate and the
//  account a dim machine handle. A single spectral light traces the cut corner.
//  On each rollover the code re-etches with a brief sharpen. Tap to copy.
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
                .padding(.top, Theme.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: code) { _, _ in pulseRefresh() }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(slab)
        .overlay { copiedBadge }
        .contentShape(ObsidianSlab())
        .onTapGesture(perform: copyCode)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.displayTitle), code \(code)")
        .accessibilityHint("Double-tap to copy")
    }

    /// The cut-obsidian surface: polished gradient, hairline rim, and the
    /// spectral light catching the cut corner.
    private var slab: some View {
        ObsidianSlab()
            .fill(Theme.slab)
            .overlay(ObsidianSlab().stroke(Theme.cardStroke, lineWidth: 1))
            .overlay(ObsidianFacet().stroke(Theme.sheen, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
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
