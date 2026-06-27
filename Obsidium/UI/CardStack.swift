//
//  CardStack.swift
//  Obsidium
//
//  An Apple Wallet–style deck. Collapsed, the cards overlap and each shows only
//  its name + username. Tapping a card pulls it out to reveal the engraved code
//  while the rest collapse into a thin pile below it; swiping the pulled-out
//  card down drops it back into the deck. Delete is a long-press context menu.
//

import SwiftUI

struct CardStack: View {
    let accounts: [Account]
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date
    let onDelete: (Account) -> Void

    @State private var selectedID: Account.ID?
    @State private var dragOffset: CGFloat = 0

    // Geometry of the deck.
    private let headerHeight: CGFloat = 66    // collapsed card height (single row)
    private let detailHeight: CGFloat = 150   // pulled-out card height
    private let stackStep: CGFloat = 54       // visible sliver per stacked card
    private let pilePeek: CGFloat = 30        // sliver per card in the bottom pile
    private let gap: CGFloat = 14             // space below the pulled-out card

    private var spring: Animation { .spring(response: 0.5, dampingFraction: 0.84) }

    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    let isSelected = selectedID == account.id
                    TokenCardView(
                        account: account,
                        now: now,
                        mode: isSelected ? .detail : .header,
                        height: isSelected ? detailHeight : headerHeight,
                        onTap: { select(account.id) }
                    )
                    .offset(y: yOffset(for: index) + (isSelected ? dragOffset : 0))
                    .zIndex(isSelected ? 1000 : Double(index))
                    .gesture(isSelected ? dragToDismiss : nil)
                    .contextMenu {
                        Button(role: .destructive) {
                            onDelete(account)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: contentHeight, alignment: .top)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.xl)
            .animation(spring, value: selectedID)
        }
        .scrollIndicators(.hidden)
        .scrollDisabled(selectedID != nil)   // let the drag dismiss, not scroll
    }

    // MARK: Layout math

    private var selectedIndex: Int? {
        guard let id = selectedID else { return nil }
        return accounts.firstIndex { $0.id == id }
    }

    private func yOffset(for index: Int) -> CGFloat {
        guard let selected = selectedIndex else {
            return CGFloat(index) * stackStep          // full deck
        }
        if index == selected { return 0 }              // pulled out to the top
        let j = index < selected ? index : index - 1   // position in the bottom pile
        return detailHeight + gap + CGFloat(j) * pilePeek
    }

    private var contentHeight: CGFloat {
        guard !accounts.isEmpty else { return 0 }
        if selectedIndex != nil {
            let others = accounts.count - 1
            guard others > 0 else { return detailHeight }
            return detailHeight + gap + CGFloat(others - 1) * pilePeek + headerHeight
        }
        return CGFloat(accounts.count - 1) * stackStep + headerHeight
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
                dragOffset = max(0, value.translation.height)   // downward only
            }
            .onEnded { value in
                if value.translation.height > 60 {
                    withAnimation(spring) { selectedID = nil; dragOffset = 0 }
                } else {
                    withAnimation(spring) { dragOffset = 0 }
                }
            }
    }
}
