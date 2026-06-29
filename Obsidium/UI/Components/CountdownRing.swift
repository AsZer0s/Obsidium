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
    var size: CGFloat = 22
    /// Ring colour while healthy. Expiring always overrides to the warning hue.
    var tint: Color = Theme.accent

    private var isExpiring: Bool { secondsRemaining <= 5 }
    private var strokeColor: Color { isExpiring ? Theme.warning : tint }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.25), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true) // the card already announces the code
    }
}
