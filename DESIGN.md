# Obsidium Design System v1

A clean, HIG-aligned authenticator. Dark-first, system typography, minimal
chrome. One rule governs everything —

> Each token is an Apple Wallet–style card, and the **code is the hero**.

Tokens live in `Obsidium/UI/Theme.swift`; the deck is `CardStack`. The code is
the source of truth; this is the spec.

## Signature — the deck

A **Wallet pull-out deck** (`CardStack`):

- **Collapsed:** cards overlap; each shows **issuer on the left, account name on
  the right** — so several accounts from one service (e.g. four Googles) stay
  distinguishable at a glance. No code shown.
- **Pull out:** tap a card → it rises to the top in `.detail` mode and reveals
  the big SF Mono code + countdown ring; the rest slide to the **bottom of the
  screen** as a readable stack — each still showing its name + username.
- **Put back:** swipe the pulled-out card down to drop it into the deck.

A subtle icon block peeks from each card's top-left (SF Symbol; swap for a
bundled FontAwesome glyph for brand marks).

## Spacing scale

4-based: `xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32`. Use these, never raw numbers.

## Type scale (system only)

| Token | Font | Role |
|-------|------|------|
| `code`   | SF Mono 44, regular, `tracking(4)` | the hero |
| `issuer` | `.headline` (SF semibold) | service name |
| `label`  | `.subheadline` (SF), `.secondary` | account name (right-aligned) |

The code uses `contentTransition(.numericText())` so digits roll, and
`minimumScaleFactor(0.6)` so 8-digit codes fit.

## Color tokens (dark)

| Token | Value | Use |
|-------|-------|-----|
| `accent`     | icy blue `#66C7EB` | countdown, copy flash, actions |
| `warning`    | amber `#F59366` | countdown when ≤ 5s |
| `card`       | `#29292E → #1D1D21` gradient | flat elevated card surface |
| `cardStroke` | white @ 9% | hairline rims |
| `background` | near-black gradient | app background |

## Card surface

A `RoundedRectangle` (radius 20) filled with `Theme.card`, a `cardStroke`
hairline rim, and a soft float shadow. No emboss, no sheen — clean and flat.
The icon block sits clipped behind the content in the top-left.

## Layout — the deck

`CardStack` positions cards in a `GeometryReader`/`ZStack` by computed `y`
offsets (no scroll, so motion animates smoothly). Each card has **one stable
content tree** — name row + code row always present — and is clipped to an
animating height: collapsed (`headerHeight` 52) the code row sits below the fold
and is clipped away; selected (`detailHeight` 132) the card grows and the clip
**wipes the code into view**. Because nothing is swapped, expanding is a real
slide-and-grow, never a crossfade.

Collapsed cards peek `stackStep` (44). Selecting slides everyone else to the
bottom of the screen, stacked with `pilePeek` (46) — wide enough to keep each
name row readable. A downward `DragGesture` past ~60pt returns the pulled card.

## Interaction

- **Tap a collapsed card** → pull it out (reveal code).
- **Tap a pulled-out card** → copy the code (crisp haptic + a bottom **toast**,
  and the code briefly flashes `accent`).
- **Swipe a pulled-out card down** → return it to the deck.
- **Long-press a card** → Edit (name, account, TOTP key) or Delete.

## Settings & security

A gear button opens **Settings**: a **Face ID** toggle that gates the sensitive
actions (delete & export), plus **Export Backup** and **Import / Restore**
(JSON via the system file exporter/importer). Backups are plain-text keys —
the screen says so. Biometrics use `.deviceOwnerAuthentication` (passcode
fallback); the toggle persists in `@AppStorage`.

## Principles checklist (apply to any new surface)

- [ ] Is the code (or primary value) the unmistakable focus?
- [ ] System fonts; supporting text demoted to `.secondary`?
- [ ] Spacing from the scale; generous, even air?
- [ ] One flat card surface; no bespoke gradients/shadows/decorations?
- [ ] Motion subtle and native (numericText, springs)?
- [ ] Dark contrast holds; accent used sparingly, warmth reserved for expiry?
