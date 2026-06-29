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
    private static let soft = UIImpactFeedbackGenerator(style: .soft)

    /// A crisp tick for "code copied".
    static func copy() {
        impact.prepare()
        impact.impactOccurred()
    }

    /// A soft bump when a card is picked up for reordering.
    static func lift() {
        soft.prepare()
        soft.impactOccurred()
    }
}
