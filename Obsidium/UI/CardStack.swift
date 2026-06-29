//
//  CardStack.swift
//  Obsidium
//
//  Apple Wallet–style stacked cards. The navigation title and toolbar stay
//  fixed; only the card area scrolls. Cards always live in one ScrollView / one
//  ZStack so expanding a card is a real animated movement from its stacked
//  position to the top, not a view replacement.
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
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedScrollOffset: CGFloat = 0

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
            ScrollView(.vertical) {
                ZStack(alignment: .top) {
                    ForEach(accounts) { account in
                        let index = index(of: account)
                        let isSelected = selectedID == account.id
                        card(account: account, isSelected: isSelected)
                            .offset(y: yOffset(for: index, in: geo.size.height) + (isSelected ? selectedScrollCompensation + dragOffset : 0))
                            .zIndex(isSelected ? 1000 : Double(index))
                            .gesture(isSelected ? dragToDismiss : nil)
                    }
                }
                .frame(width: geo.size.width, height: max(geo.size.height, contentHeight(in: geo.size.height)), alignment: .top)
            }
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                max(0, geometry.contentOffset.y)
            } action: { _, newValue in
                scrollOffset = newValue
            }
            .animation(spring, value: selectedID)
        }
    }

    // MARK: Layout

    private var selectedIndex: Int? {
        guard let id = selectedID else { return nil }
        return accounts.firstIndex { $0.id == id }
    }

    private var selectedScrollCompensation: CGFloat {
        max(0, scrollOffset - selectedScrollOffset)
    }

    private func contentHeight(in height: CGFloat) -> CGFloat {
        guard selectedIndex != nil else {
            return collapsedTopInset + CGFloat(max(accounts.count - 1, 0)) * stackStep + headerHeight + bottomInset
        }
        let others = max(accounts.count - 1, 0)
        let pileTop = expandedPileTop(in: height)
        return pileTop + CGFloat(max(others - 1, 0)) * pilePeek + headerHeight + bottomInset
    }

    private func index(of account: Account) -> Int {
        accounts.firstIndex { $0.id == account.id } ?? 0
    }

    private func yOffset(for index: Int, in height: CGFloat) -> CGFloat {
        guard let selected = selectedIndex else {
            return collapsedTopInset + CGFloat(index) * stackStep
        }

        if index == selected { return topInset }

        let pileTop = expandedPileTop(in: height)
        let j = index < selected ? index : index - 1
        return pileTop + CGFloat(j) * pilePeek
    }

    private func expandedPileTop(in height: CGFloat) -> CGFloat {
        let others = max(accounts.count - 1, 0)
        let pileHeight = CGFloat(max(others - 1, 0)) * pilePeek + headerHeight
        let naturalTop = topInset + detailHeight + gap
        let bottomAlignedTop = height - expandedPileBottomGap - pileHeight
        return max(naturalTop, bottomAlignedTop)
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

    private func select(_ id: Account.ID) {
        withAnimation(spring) {
            if selectedID == id {
                selectedID = nil
                selectedScrollOffset = 0
            } else {
                selectedID = id
                selectedScrollOffset = scrollOffset
            }
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
                        selectedScrollOffset = 0
                        dragOffset = 0
                    }
                } else {
                    withAnimation(spring) { dragOffset = 0 }
                }
            }
    }
}
