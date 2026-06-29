//
//  CardStack.swift
//  Obsidium
//
//  Apple Wallet–style stacked cards. The navigation title and toolbar stay
//  fixed; only the card area scrolls. Collapsed cards overlap into a tall
//  wallet stack. Tap a card and it pulls out to the top, while the remaining
//  cards form a separately scrollable stacked pile underneath.
//
//  Card editing, deleting, and reordering live in Settings → Manage Tokens.
//

import SwiftUI

struct CardStack: View {
    let accounts: [Account]
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date

    @State private var selectedID: Account.ID?
    @State private var dragOffset: CGFloat = 0

    // Geometry of the deck.
    private let headerHeight: CGFloat = 86
    private let detailHeight: CGFloat = 148
    private let stackStep: CGFloat = 70
    private let pilePeek: CGFloat = 72
    private let gap: CGFloat = 16
    private let topInset: CGFloat = 8
    private let bottomInset: CGFloat = 32

    private var spring: Animation { .spring(response: 0.46, dampingFraction: 0.84) }

    var body: some View {
        GeometryReader { geo in
            deck(in: geo.size)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }

    @ViewBuilder
    private func deck(in size: CGSize) -> some View {
        if let selectedIndex, accounts.indices.contains(selectedIndex) {
            expandedDeck(selectedIndex: selectedIndex, in: size)
        } else {
            collapsedDeck(in: size)
        }
    }

    // MARK: Collapsed stack

    private func collapsedDeck(in size: CGSize) -> some View {
        ScrollView(.vertical) {
            ZStack(alignment: .top) {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    card(account: account, isSelected: false)
                        .offset(y: topInset + CGFloat(index) * stackStep)
                        .zIndex(Double(index))
                }
            }
            .frame(width: size.width, height: max(size.height, collapsedContentHeight), alignment: .top)
        }
        .scrollIndicators(.hidden)
        .animation(spring, value: selectedID)
    }

    private var collapsedContentHeight: CGFloat {
        topInset + CGFloat(max(accounts.count - 1, 0)) * stackStep + headerHeight + bottomInset
    }

    // MARK: Expanded stack

    private func expandedDeck(selectedIndex: Int, in size: CGSize) -> some View {
        let selected = accounts[selectedIndex]
        let others = accounts.enumerated()
            .filter { $0.offset != selectedIndex }
            .map(\.element)
        let pileTop = topInset + detailHeight + gap
        let pileHeight = max(0, size.height - pileTop)

        return ZStack(alignment: .top) {
            card(account: selected, isSelected: true)
                .offset(y: topInset + dragOffset)
                .zIndex(1000)
                .gesture(dragToDismiss)

            ScrollView(.vertical) {
                ZStack(alignment: .top) {
                    ForEach(Array(others.enumerated()), id: \.element.id) { index, account in
                        card(account: account, isSelected: false)
                            .offset(y: topInset + CGFloat(index) * pilePeek)
                            .zIndex(Double(index))
                    }
                }
                .frame(width: size.width, height: max(pileHeight, pileContentHeight(count: others.count)), alignment: .top)
            }
            .scrollIndicators(.hidden)
            .frame(width: size.width, height: pileHeight, alignment: .top)
            .offset(y: pileTop)
        }
        .frame(width: size.width, height: size.height, alignment: .top)
        .animation(spring, value: selectedID)
    }

    private func pileContentHeight(count: Int) -> CGFloat {
        topInset + CGFloat(max(count - 1, 0)) * pilePeek + headerHeight + bottomInset
    }

    // MARK: Card

    private func card(account: Account, isSelected: Bool) -> some View {
        TokenCardView(
            account: account,
            now: now,
            mode: isSelected ? .detail : .header,
            height: isSelected ? detailHeight : headerHeight,
            onTap: { select(account.id) }
        )
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: Interaction

    private var selectedIndex: Int? {
        guard let id = selectedID else { return nil }
        return accounts.firstIndex { $0.id == id }
    }

    private func select(_ id: Account.ID) {
        withAnimation(spring) {
            selectedID = (selectedID == id) ? nil : id
            dragOffset = 0
        }
    }

    private var dragToDismiss: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                if value.translation.height > 60 {
                    withAnimation(spring) {
                        selectedID = nil
                        dragOffset = 0
                    }
                } else {
                    withAnimation(spring) { dragOffset = 0 }
                }
            }
    }
}
