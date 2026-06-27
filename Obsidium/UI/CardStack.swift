//
//  CardStack.swift
//  Obsidium
//
//  An Apple Wallet–style deck. Collapsed, the cards overlap and only the top of
//  each peeks out; expanded, they spring apart into a spaced list. Tapping a
//  collapsed card expands the deck; tapping an expanded card copies its code.
//  (Delete is via long-press context menu, since the overlapping deck has no
//  room for swipe actions.)
//

import SwiftUI

struct CardStack: View {
    let accounts: [Account]
    @Binding var expanded: Bool
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date
    let onDelete: (Account) -> Void

    private let cardHeight: CGFloat = 134
    private let peek: CGFloat = 88   // visible height of an overlapped card

    var body: some View {
        ScrollView {
            // Negative spacing overlaps the cards; each later card is drawn on
            // top, so every card's top `peek` stays visible — a Wallet deck.
            VStack(spacing: expanded ? Theme.Spacing.md : peek - cardHeight) {
                ForEach(accounts) { account in
                    TokenCardView(
                        account: account,
                        now: now,
                        height: cardHeight,
                        stacked: !expanded,
                        onStackTap: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.84)) {
                                expanded = true
                            }
                        }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            onDelete(account)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
    }
}
