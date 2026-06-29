//
//  CardStack.swift
//  Obsidium
//
//  A simple, stable card scroller. The navigation title and toolbar stay fixed;
//  only the card area scrolls. Tap a card to expand it inline and reveal the
//  code, tap again to collapse. Long-press a card for the Edit / Delete menu.
//  Reordering lives in Settings → Reorder Tokens.
//

import SwiftUI

struct CardStack: View {
    let accounts: [Account]
    /// Current time, supplied by the enclosing TimelineView.
    let now: Date
    let onEdit: (Account) -> Void
    let onDelete: (Account) -> Void

    @State private var selectedID: Account.ID?
    @State private var menuAccount: Account?

    private let headerHeight: CGFloat = 86
    private let detailHeight: CGFloat = 148
    private var spring: Animation { .spring(response: 0.42, dampingFraction: 0.86) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                ScrollView(.vertical) {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        ForEach(accounts) { account in
                            let isSelected = selectedID == account.id
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
                    }
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, Theme.Spacing.xxl)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .disabled(menuAccount != nil)
                .animation(spring, value: selectedID)

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

    private func select(_ id: Account.ID) {
        withAnimation(spring) {
            selectedID = (selectedID == id) ? nil : id
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
