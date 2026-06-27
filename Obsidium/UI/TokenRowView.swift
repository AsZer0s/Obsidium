//
//  TokenRowView.swift
//  Obsidium
//
//  One row in the token list: issuer/label, the current code, and a countdown
//  ring. Receives the current time from the parent TimelineView so all rows
//  refresh in lockstep. Tap to copy the code.
//

import SwiftUI

struct TokenRowView: View {
    let account: Account
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date

    @State private var didCopy = false

    private var code: String {
        TOTPGenerator.code(for: account, at: now) ?? "------"
    }

    /// Group the code into two halves for readability, e.g. "123 456".
    private var formattedCode: String {
        guard code.count == 6 || code.count == 8 else { return code }
        let mid = code.index(code.startIndex, offsetBy: code.count / 2)
        return "\(code[..<mid]) \(code[mid...])"
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.displayTitle)
                    .font(.headline)
                if !account.label.isEmpty, account.displayTitle != account.label {
                    Text(account.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(formattedCode)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(didCopy ? Color.accentColor : .primary)
            }

            Spacer()

            CountdownRing(
                progress: TOTPGenerator.progress(period: account.period, at: now),
                secondsRemaining: TOTPGenerator.secondsRemaining(period: account.period, at: now)
            )
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { copyCode() }
        .overlay(alignment: .trailing) {
            if didCopy {
                Text("Copied")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
                    .offset(y: -28)
                    .transition(.opacity)
            }
        }
    }

    private func copyCode() {
        guard code != "------" else { return }
        UIPasteboard.general.string = code
        withAnimation { didCopy = true }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { didCopy = false }
        }
    }
}
