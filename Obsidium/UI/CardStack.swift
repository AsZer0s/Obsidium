//
//  CardStack.swift
//  Obsidium
//
//  Apple Wallet–style fixed stacked cards. Cards do not scroll; the deck uses
//  stable offsets so tap-to-expand animates cleanly from the collapsed stack to
//  the pulled-out card. Editing, deleting, and reordering live in
//  Settings → Manage Tokens.
//

import SwiftUI

struct CardStack: View {
    let accounts: [Account]
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date

    @State private var selectedID: Account.ID?
    @State private var dragOffset: CGFloat = 0

    // Geometry of the deck.
    private let headerHeight: CGFloat = 132
    private let detailHeight: CGFloat = 148
    private let stackStep: CGFloat = 50
    private let pilePeek: CGFloat = 52
    private let gap: CGFloat = 16
    private let topInset: CGFloat = 8
    private let collapsedTopInset: CGFloat = 42
    private let bottomInset: CGFloat = 5

    private var spring: Animation { .spring(response: 0.48, dampingFraction: 0.84) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    let isSelected = selectedID == account.id
                    card(account: account, isSelected: isSelected)
                        .offset(y: yOffset(for: index, in: geo.size.height) + (isSelected ? dragOffset : 0))
                        .zIndex(isSelected ? 1000 : Double(index))
                        .gesture(isSelected ? dragToDismiss : nil)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .clipped()
            .animation(spring, value: selectedID)
            .onChange(of: accounts.map(\.id)) { _, ids in
                if let id = selectedID, !ids.contains(id) {
                    selectedID = nil
                    dragOffset = 0
                }
            }
        }
    }

    // MARK: Layout

    private var selectedIndex: Int? {
        guard let id = selectedID else { return nil }
        return accounts.firstIndex { $0.id == id }
    }

    private func yOffset(for index: Int, in height: CGFloat) -> CGFloat {
        guard let selected = selectedIndex else {
            return collapsedTopInset + CGFloat(index) * stackStep
        }
        if index == selected { return topInset }

        let j = index < selected ? index : index - 1
        return expandedPileTop(in: height) + CGFloat(j) * pilePeek
    }

    private func expandedPileTop(in height: CGFloat) -> CGFloat {
        let others = max(accounts.count - 1, 0)
        let pileHeight = CGFloat(max(others - 1, 0)) * pilePeek + headerHeight
        let naturalTop = topInset + detailHeight + gap
        let bottomAlignedTop = height - bottomInset - pileHeight
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
