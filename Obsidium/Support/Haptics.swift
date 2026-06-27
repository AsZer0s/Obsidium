//
//  Haptics.swift
//  Obsidium
//
//  Small, prepared haptic feedback. Preparing the generator before use cuts
//  latency so the tap feels immediate.
//

import UIKit

enum Haptics {
    private static let impact = UIImpactFeedbackGenerator(style: .rigid)

    /// A crisp tick for "code copied".
    static func copy() {
        impact.prepare()
        impact.impactOccurred()
    }
}
