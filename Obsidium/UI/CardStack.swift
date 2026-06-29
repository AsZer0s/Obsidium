//
//  CardStack.swift
//  Obsidium
//
//  An Apple Wallet–style deck. Collapsed, the cards overlap and scroll like a
//  long wallet stack. Tap a card and it rises to the top to reveal the code;
//  the remaining cards form their own independently scrollable bottom pile.
//  Swipe the pulled-out card down to drop it back. Long-press a card for the
//  Edit / Delete menu. Reordering lives in Settings → Reorder Tokens.
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
    @State private var menuAccount: Account?

    // Geometry of the deck.
    private let headerHeight: CGFloat = 86    // collapsed: more card-like, not a thin strip
    private let detailHeight: CGFloat = 148   // pulled-out: name + code (slides in)
    private let stackStep: CGFloat = 70        // visible sliver per stacked card
    private let pilePeek: CGFloat = 72         // visible sliver per bottom-pile card
    private let gap: CGFloat = 16             // min space below the pulled-out card
    private let topInset: CGFloat = 8
    private let bottomInset: CGFloat = 12

    private var spring: Animation { .spring(response: 0.46, dampingFraction: 0.82) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Group {
                    if let selectedIndex, accounts.indices.contains(selectedIndex) {
                        expandedDeck(selectedIndex: selectedIndex, in: geo.size)
                    } else {
                        collapsedDeck(in: geo.size)
                    }
                }
                .disabled(menuAccount != nil)

                if let menuAccount {
                    Color.black.opacity(0.30)
                        .ignoresSafeArea()
                        .onTapGesture { self.menuAccount = nil }
                        .transition(.opacity)

                    TokenActionMenu(
                        account: menuAccount,
                        onEdit: {
                            self.menuAccount = nil
                            onEdit(menuAccount)
                        },
                        onDelete: {
                            self.menuAccount = nil
                            onDelete(menuAccount)
                        },
                        onCancel: { self.menuAccount = nil }
                    )
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(3000)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .animation(.snappy, value: menuAccount)
    }

    // MARK: Layout

    private var selectedIndex: Int? {
        guard let id = selectedID else { return nil }
        return accounts.firstIndex { $0.id == id }
    }

    private var collapsedContentHeight: CGFloat {
        topInset + CGFloat(max(accounts.count - 1, 0)) * stackStep + headerHeight + bottomInset
    }

    private func pileContentHeight(count: Int) -> CGFloat {
        topInset + CGFloat(max(count - 1, 0)) * pilePeek + headerHeight + bottomInset
    }

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

    private func expandedDeck(selectedIndex: Int, in size: CGSize) -> some View {
        let selected = accounts[selectedIndex]
        let others = accounts.enumerated().filter { $0.offset != selectedIndex }.map(\.element)
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

    private func card(account: Account, isSelected: Bool) -> some View {
        TokenCardView(
            account: account,
            now: now,
            mode: isSelected ? .detail : .header,
            height: isSelected ? detailHeight : headerHeight,
            onTap: { select(account.id) }
        )
        .padding(.horizontal, Theme.Spacing.lg)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in
            menuAccount = account
        })
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
                    withAnimation(spring) { selectedID = nil; dragOffset = 0 }
                } else {
                    withAnimation(spring) { dragOffset = 0 }
                }
            }
    }

}

private struct TokenActionMenu: View {
    let account: Account
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            VStack(spacing: 0) {
                Text(account.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.vertical, Theme.Spacing.md)

                Divider()

                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                }

                Divider()

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )

            Button(action: onCancel) {
                Text("Cancel")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )
        }
    }
}
