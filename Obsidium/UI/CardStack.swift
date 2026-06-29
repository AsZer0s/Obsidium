//
//  CardStack.swift
//  Obsidium
//
//  Apple Wallet–style stacked cards. The navigation title and toolbar stay
//  fixed; only the card area scrolls. Collapsed cards overlap into a wallet
//  stack. Once a card is expanded, that card is pinned outside the ScrollView
//  while the remaining collapsed pile scrolls underneath.
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
    @Namespace private var cardNamespace

    // Geometry of the deck.
    private let headerHeight: CGFloat = 132
    private let detailHeight: CGFloat = 148
    private let stackStep: CGFloat = 50
    private let pilePeek: CGFloat = 52
    private let gap: CGFloat = 16
    private let topInset: CGFloat = 8
    private let collapsedTopInset: CGFloat = 42
    private let bottomInset: CGFloat = 32
    private let expandedPileBottomGap: CGFloat = 5

    private var spring: Animation { .spring(response: 0.48, dampingFraction: 0.84) }

    var body: some View {
        GeometryReader { geo in
            if let selectedIndex, accounts.indices.contains(selectedIndex) {
                expandedDeck(selectedIndex: selectedIndex, in: geo.size)
            } else {
                collapsedDeck(in: geo.size)
            }
        }
        .animation(spring, value: selectedID)
    }

    // MARK: Collapsed stack

    private func collapsedDeck(in size: CGSize) -> some View {
        ScrollView(.vertical) {
            ZStack(alignment: .top) {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    card(account: account, isSelected: false)
                        .matchedGeometryEffect(id: account.id, in: cardNamespace)
                        .offset(y: collapsedTopInset + CGFloat(index) * stackStep)
                        .zIndex(Double(index))
                }
            }
            .frame(width: size.width, height: max(size.height, collapsedContentHeight), alignment: .top)
        }
        .scrollIndicators(.hidden)
    }

    private var collapsedContentHeight: CGFloat {
        collapsedTopInset + CGFloat(max(accounts.count - 1, 0)) * stackStep + headerHeight + bottomInset
    }

    // MARK: Expanded stack

    private func expandedDeck(selectedIndex: Int, in size: CGSize) -> some View {
        let selected = accounts[selectedIndex]
        let others = accounts.enumerated()
            .filter { $0.offset != selectedIndex }
            .map(\.element)
        let pileTop = expandedPileTop(otherCount: others.count, in: size.height)
        let pileViewportHeight = max(0, size.height - pileTop)

        return ZStack(alignment: .top) {
            ScrollView(.vertical) {
                ZStack(alignment: .top) {
                    ForEach(Array(others.enumerated()), id: \.element.id) { index, account in
                        card(account: account, isSelected: false)
                            .matchedGeometryEffect(id: account.id, in: cardNamespace)
                            .offset(y: topInset + CGFloat(index) * pilePeek)
                            .zIndex(Double(index))
                    }
                }
                .frame(
                    width: size.width,
                    height: max(pileViewportHeight, pileContentHeight(count: others.count)),
                    alignment: .top
                )
            }
            .scrollIndicators(.hidden)
            .frame(width: size.width, height: pileViewportHeight, alignment: .top)
            .offset(y: pileTop)

            card(account: selected, isSelected: true)
                .matchedGeometryEffect(id: selected.id, in: cardNamespace)
                .offset(y: topInset + dragOffset)
                .zIndex(1000)
                .gesture(dragToDismiss)
        }
        .frame(width: size.width, height: size.height, alignment: .top)
    }

    private func expandedPileTop(otherCount: Int, in height: CGFloat) -> CGFloat {
        let pileHeight = CGFloat(max(otherCount - 1, 0)) * pilePeek + headerHeight
        let naturalTop = topInset + detailHeight + gap
        let bottomAlignedTop = height - expandedPileBottomGap - pileHeight
        return max(naturalTop, bottomAlignedTop)
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
