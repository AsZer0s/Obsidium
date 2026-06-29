//
//  CardStack.swift
//  Obsidium
//
//  An Apple Wallet–style deck. Collapsed, the cards overlap and each shows its
//  name + username. Tap a card and it rises to the top to reveal the code while
//  the rest slide to the BOTTOM of the screen as a still-readable stack. Swipe
//  the pulled-out card down to drop it back.
//
//  Long-press interaction (Wallet-style):
//   • Long-press a collapsed card and *move* → drag-to-reorder (no menu).
//   • Long-press a collapsed card and *hold still* → Edit/Delete menu.
//   • Long-press the pulled-out card → Edit/Delete context menu.
//

import SwiftUI

struct CardStack: View {
    let accounts: [Account]
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date
    let onEdit: (Account) -> Void
    let onDelete: (Account) -> Void
    /// Live, in-memory reorder (called on every slot crossing during a drag).
    let onMove: (Int, Int) -> Void
    /// Persist the order once the reorder drag finishes.
    let onCommitOrder: () -> Void

    @State private var selectedID: Account.ID?
    @State private var dragOffset: CGFloat = 0

    // Reorder state.
    @State private var draggingID: Account.ID?
    @State private var dragStartSlotY: CGFloat = 0
    @State private var dragTranslation: CGFloat = 0
    @State private var didReorder = false
    @State private var menuAccount: Account?

    // Geometry of the deck.
    private let headerHeight: CGFloat = 58    // collapsed: name row only
    private let detailHeight: CGFloat = 140   // pulled-out: name + code (slides in)
    private let stackStep: CGFloat = 48        // visible sliver per stacked card
    private let pilePeek: CGFloat = 50         // sliver per bottom-pile card —
                                               // wide enough to keep the name row readable
    private let gap: CGFloat = 16             // min space below the pulled-out card
    private let topInset: CGFloat = 8
    private let bottomInset: CGFloat = 12

    private var spring: Animation { .spring(response: 0.46, dampingFraction: 0.82) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    cardView(account: account, index: index, geoHeight: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .animation(spring, value: selectedID)
        }
        .confirmationDialog(
            menuAccount?.displayTitle ?? "",
            isPresented: menuPresented,
            titleVisibility: .visible,
            presenting: menuAccount
        ) { account in
            Button("Edit") { onEdit(account) }
            Button("Delete", role: .destructive) { onDelete(account) }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func cardView(account: Account, index: Int, geoHeight: CGFloat) -> some View {
        let isSelected = selectedID == account.id
        let isDragging = draggingID == account.id
        let offsetY = isDragging
            ? dragStartSlotY + dragTranslation
            : yOffset(for: index, in: geoHeight) + (isSelected ? dragOffset : 0)

        let base = TokenCardView(
            account: account,
            now: now,
            mode: isSelected ? .detail : .header,
            height: isSelected ? detailHeight : headerHeight,
            onTap: { select(account.id) }
        )
        .padding(.horizontal, Theme.Spacing.lg)
        .scaleEffect(isDragging ? 1.04 : 1)
        .shadow(color: .black.opacity(isDragging ? 0.45 : 0), radius: 18, y: 10)
        .offset(y: offsetY)
        .zIndex(isDragging ? 2000 : (isSelected ? 1000 : Double(index)))

        if isSelected {
            base
                .gesture(dragToDismiss)
                .contextMenu {
                    Button { onEdit(account) } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { onDelete(account) } label: { Label("Delete", systemImage: "trash") }
                }
        } else {
            base
                .gesture(reorderGesture(for: account, index: index, geoHeight: geoHeight))
        }
    }

    // MARK: Layout math

    private var selectedIndex: Int? {
        guard let id = selectedID else { return nil }
        return accounts.firstIndex { $0.id == id }
    }

    private func yOffset(for index: Int, in height: CGFloat) -> CGFloat {
        guard let selected = selectedIndex else { return topInset + CGFloat(index) * stackStep }
        if index == selected { return topInset }

        let j = index < selected ? index : index - 1
        return pileTop(in: height) + CGFloat(j) * pilePeek
    }

    private func pileTop(in height: CGFloat) -> CGFloat {
        let others = accounts.count - 1
        let pileHeight = CGFloat(max(0, others - 1)) * pilePeek + headerHeight
        return max(topInset + detailHeight + gap, height - bottomInset - pileHeight)
    }

    /// Map a vertical position to the array index whose slot is nearest.
    private func targetIndex(forY y: CGFloat, in height: CGFloat) -> Int {
        if let selected = selectedIndex {
            let j = Int(((y - pileTop(in: height)) / pilePeek).rounded())
            let clampedJ = min(max(j, 0), max(0, accounts.count - 2))
            return clampedJ < selected ? clampedJ : clampedJ + 1
        } else {
            let i = Int(((y - topInset) / stackStep).rounded())
            return min(max(i, 0), accounts.count - 1)
        }
    }

    // MARK: Interaction

    private func select(_ id: Account.ID) {
        withAnimation(spring) {
            selectedID = (selectedID == id) ? nil : id
            dragOffset = 0
        }
    }

    /// Drag the pulled-out card down to drop it back into the deck.
    private var dragToDismiss: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                if value.translation.height > 60 {
                    withAnimation(spring) { selectedID = nil; dragOffset = 0 }
                } else {
                    withAnimation(spring) { dragOffset = 0 }
                }
            }
    }

    /// Long-press to pick up, then move to reorder. Releasing without a move
    /// opens the Edit/Delete menu instead.
    private func reorderGesture(for account: Account, index: Int, geoHeight: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.4)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .first(true):
                    beginDrag(account: account, index: index, geoHeight: geoHeight)
                case .second(true, let drag):
                    if let drag { updateDrag(translation: drag.translation.height, in: geoHeight) }
                default:
                    break
                }
            }
            .onEnded { _ in
                guard draggingID == account.id else { return }
                let movedFar = abs(dragTranslation) > 10
                if didReorder || movedFar {
                    endDrag(commit: didReorder)
                } else {
                    endDrag(commit: false)
                    menuAccount = account
                }
            }
    }

    private func beginDrag(account: Account, index: Int, geoHeight: CGFloat) {
        guard draggingID == nil else { return }
        draggingID = account.id
        dragStartSlotY = yOffset(for: index, in: geoHeight)
        dragTranslation = 0
        didReorder = false
        Haptics.lift()
    }

    private func updateDrag(translation: CGFloat, in height: CGFloat) {
        dragTranslation = translation
        guard let from = accounts.firstIndex(where: { $0.id == draggingID }) else { return }
        let to = targetIndex(forY: dragStartSlotY + translation, in: height)
        if to != from {
            withAnimation(spring) { onMove(from, to) }
            didReorder = true
        }
    }

    private func endDrag(commit: Bool) {
        if commit { onCommitOrder() }
        withAnimation(spring) {
            draggingID = nil
            dragTranslation = 0
        }
        didReorder = false
    }

    private var menuPresented: Binding<Bool> {
        Binding(
            get: { menuAccount != nil },
            set: { if !$0 { menuAccount = nil } }
        )
    }
}
