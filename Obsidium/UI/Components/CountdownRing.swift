//
//  CountdownRing.swift
//  Obsidium
//
//  Demoted, lightweight countdown feedback. The ring is no longer a hero
//  element — it lives as a small chip in the card header (precise seconds)
//  plus a thin ambient bar hugging the card's bottom edge.
//

import SwiftUI

/// A compact draining ring. Peripheral, glanceable status.
struct CountdownRing: View {
    let progress: Double
    let secondsRemaining: Int
    var size: CGFloat = 16

    private var isExpiring: Bool { secondsRemaining <= 5 }
    private var tint: Color { isExpiring ? Theme.warning : Theme.accent }

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.10), lineWidth: 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)
        }
        .frame(width: size, height: size)
    }
}

/// Ring + seconds, shown as a subtle chip in the card header.
struct CountdownChip: View {
    let progress: Double
    let secondsRemaining: Int

    private var isExpiring: Bool { secondsRemaining <= 5 }
    private var tint: Color { isExpiring ? Theme.warning : Theme.accent }

    var body: some View {
        HStack(spacing: Theme.Spacing.xs + 2) {
            CountdownRing(progress: progress, secondsRemaining: secondsRemaining)
            Text("\(secondsRemaining)s")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(.white.opacity(0.05), in: Capsule())
    }
}

/// Thin ambient progress bar that drains along the bottom edge of a card.
struct CountdownBar: View {
    let progress: Double
    let isExpiring: Bool

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill((isExpiring ? Theme.warning : Theme.accent).opacity(0.75))
                .frame(width: max(0, geo.size.width * progress))
                .animation(.linear(duration: 0.25), value: progress)
        }
        .frame(height: 2)
    }
}
