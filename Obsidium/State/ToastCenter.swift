//
//  ToastCenter.swift
//  Obsidium
//
//  A tiny app-level toast queue. Views observe `message`; setting it shows the
//  toast, and it auto-clears after a short delay. One source of truth so any
//  view (e.g. a card on copy) can raise a toast the root screen renders.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class ToastCenter {
    private(set) var message: String?
    private var generation = 0

    /// Show `text`, replacing any current toast, then auto-dismiss.
    func show(_ text: String, duration: Duration = .seconds(1.6)) {
        message = text
        generation += 1
        let current = generation
        Task {
            try? await Task.sleep(for: duration)
            if current == generation { message = nil }
        }
    }
}
