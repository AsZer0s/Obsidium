//
//  CardStack.swift
//  Obsidium
//
//  An Apple Wallet–style deck. Collapsed, the cards overlap and each shows its
//  name + username. Tap a card and it rises to the top to reveal the code while
//  the rest slide to the BOTTOM of the screen as a still-readable stack (each
//  keeps showing its name + username). Swipe the pulled-out card down to drop
//  it back. Delete is a long-press context menu.
//

import SwiftUI

struct CardStack: View {
    let accounts: [Account]
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date
    let onEdit: (Account) -> Void
    let onDelete: (Account) -> Void

    @State private var selectedID: Account.ID?
    @State private var dragOffset: CGFloat = 0

    // Geometry of the deck. headerHeight stays below the code's y-position
    // (~62) so the code row is clipped away until a card is pulled out.
    private let headerHeight: CGFloat = 52    // collapsed: name row only
    private let detailHeight: CGFloat = 132   // pulled-out: name + code rows
    private let stackStep: CGFloat = 44        // visible sliver per stacked card
    private let pilePeek: CGFloat = 46         // sliver per bottom-pile card —
                                               // wide enough to keep the name row readable
    private let gap: CGFloat = 16             // min space below the pulled-out card
    private let topInset: CGFloat = 8
    private let bottomInset: CGFloat = 12

    private var spring: Animation { .spring(response: 0.5, dampingFraction: 0.84) }

    var body: some View {
        GeometryReader { geo in
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
                    .padding(.horizontal, Theme.Spacing.lg)
                    .offset(y: yOffset(for: index, in: geo.size.height) + (isSelected ? dragOffset : 0))
                    .zIndex(isSelected ? 1000 : Double(index))
                    .gesture(isSelected ? dragToDismiss : nil)
                    .contextMenu {
                        Button {
                            onEdit(account)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            onDelete(account)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .animation(spring, value: selectedID)
        }
    }

    // MARK: Layout math

    private var selectedIndex: Int? {
        guard let id = selectedID else { return nil }
        return accounts.firstIndex { $0.id == id }
    }

    private func yOffset(for index: Int, in height: CGFloat) -> CGFloat {
        guard let selected = selectedIndex else {
            return topInset + CGFloat(index) * stackStep      // collapsed deck
        }
        if index == selected { return topInset }              // pulled out to the top

        // Everyone else stacks at the bottom of the screen, each still peeking
        // `pilePeek` so the name + username row stays visible.
        let j = index < selected ? index : index - 1
        let others = accounts.count - 1
        let pileHeight = CGFloat(max(0, others - 1)) * pilePeek + headerHeight
        let pileTop = max(topInset + detailHeight + gap, height - bottomInset - pileHeight)
        return pileTop + CGFloat(j) * pilePeek
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
