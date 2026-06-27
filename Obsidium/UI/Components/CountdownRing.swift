//
//  CountdownRing.swift
//  Obsidium
//
//  A circular indicator showing how much time remains in the current TOTP
//  step. Driven by the enclosing TimelineView — it just renders the value it
//  is given.
//

import SwiftUI

struct CountdownRing: View {
    /// Fraction of the period remaining, 0...1.
    let progress: Double
    /// Whole seconds remaining, shown in the centre.
    let secondsRemaining: Int

    /// Turn red as the step is about to expire.
    private var isExpiring: Bool { secondsRemaining <= 5 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isExpiring ? Color.red : Color.accentColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // start at 12 o'clock
                .animation(.linear(duration: 0.25), value: progress)

            Text("\(secondsRemaining)")
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(isExpiring ? .red : .secondary)
        }
        .frame(width: 28, height: 28)
    }
}
