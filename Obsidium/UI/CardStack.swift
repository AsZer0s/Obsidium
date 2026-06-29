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

    // Geometry of the deck.
    private let headerHeight: CGFloat = 86
    private let detailHeight: CGFloat = 148
    private let stackStep: CGFloat = 70
    private let pilePeek: CGFloat = 72
    private let gap: CGFloat = 16
    private let topInset: CGFloat = 8
    private let collapsedTopInset: CGFloat = 42
    private let bottomInset: CGFloat = 32

    private var spring: Animation { .spring(response: 0.48, dampingFraction: 0.84) }

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical) {
                ZStack(alignment: .top) {
                    ForEach(accounts) { account in
                        let index = index(of: account)
                        let isSelected = selectedID == account.id
                        card(account: account, isSelected: isSelected)
                            .offset(y: yOffset(for: index, in: geo.size.height) + (isSelected ? scrollOffset + dragOffset : 0))
                            .zIndex(isSelected ? 1000 : Double(index))
                            .gesture(isSelected ? dragToDismiss : nil)
                    }
                }
                .frame(width: geo.size.width, height: max(geo.size.height, contentHeight), alignment: .top)
                .background(alignment: .top) {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: CardStackScrollOffsetKey.self,
                            value: max(0, -proxy.frame(in: .named("cardStackScroll")).minY)
                        )
                    }
                }
            }
            .coordinateSpace(name: "cardStackScroll")
            .scrollIndicators(.hidden)
            .onPreferenceChange(CardStackScrollOffsetKey.self) { scrollOffset = $0 }
            .animation(spring, value: selectedID)
        }
    }

    // MARK: Layout

    private var selectedIndex: Int? {
        guard let id = selectedID else { return nil }
        return accounts.firstIndex { $0.id == id }
    }

    private var contentHeight: CGFloat {
        guard selectedIndex != nil else {
            return collapsedTopInset + CGFloat(max(accounts.count - 1, 0)) * stackStep + headerHeight + bottomInset
        }
        let others = max(accounts.count - 1, 0)
        let pileTop = topInset + detailHeight + gap
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

        let pileTop = topInset + detailHeight + gap
        let j = index < selected ? index : index - 1
        return pileTop + CGFloat(j) * pilePeek
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

private struct CardStackScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
