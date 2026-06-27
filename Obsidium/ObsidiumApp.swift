//
//  ObsidiumApp.swift
//  Obsidium
//
//  App entry point. Creates the single VaultStore, injects it into the
//  environment, and loads persisted tokens on launch.
//

import SwiftUI

@main
struct ObsidiumApp: App {
    @State private var store = VaultStore()

    var body: some Scene {
        WindowGroup {
            TokenListView()
                .environment(store)
                .onAppear { store.load() }
        }
    }
}
