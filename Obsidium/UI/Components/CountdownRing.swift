//
//  CountdownRing.swift
//  Obsidium
//
//  The only countdown element: a small, quiet ring in the card's top-right.
//  No numeric seconds and no progress bar — anything more competes with the
//  code for attention. Color shifts to coral as the step is about to expire.
//

import SwiftUI

struct CountdownRing: View {
    let progress: Double
    let secondsRemaining: Int
    var size: CGFloat = 20

    private var isExpiring: Bool { secondsRemaining <= 5 }
    private var tint: Color { isExpiring ? Theme.warning : Theme.accent }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.10), lineWidth: 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true) // the card already announces the code
    }
}
