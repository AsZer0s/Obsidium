# Obsidium Design System v1

The visual language: **polished volcanic glass.** Each token is a slab of cut
obsidian; a single spectral light catches its cut edge; and the code is

> engraved into the stone — the **only hero**.

All tokens live in `Obsidium/UI/Theme.swift`. The signature silhouette is
`ObsidianSlab` (`UI/Components/ObsidianSlab.swift`). The code is the source of
truth; this is the spec.

## Signature

Two things carry the identity:

1. **Wallet-style stacked deck** — cards collapse into an overlapping pile and
   spring apart into a spaced list (`CardStack`). Stacked, only each card's top
   `peek` shows; tap a collapsed card to expand, tap an expanded card to copy.
2. **Background icon block** — an oversized glyph pushed up-left so only its
   bottom-right corner peeks into each card's top-left, at ~8% accent opacity.
   (SF Symbol today; swap for a bundled FontAwesome brand glyph if desired.)

The slab itself is a clean rounded rectangle (radius 20) with a faded **spectral
sheen line** across its top edge — obsidian's glassy catch of light.

## Spacing scale

A single 4-based scale. Use these, never raw numbers.

| Token | Value | Typical use |
|-------|-------|-------------|
| `xs`  | 4  | tight metadata gaps |
| `sm`  | 8  | inline gaps, chip padding |
| `md`  | 12 | chip/badge padding |
| `lg`  | 16 | card horizontal padding, metadata→code gap |
| `xl`  | 24 | card vertical padding ("air"), screen padding |
| `xxl` | 32 | empty-state breathing room |

## Type scale

A deliberate three-voice pairing (system faces only — nothing to bundle):

| Token | Font | Role / voice |
|-------|------|------|
| `code`   | SF Mono 46, medium, `tracking(6)`, emboss shadow | engraved hero |
| `issuer` | **New York serif** footnote, medium | nameplate (human) |
| `label`  | SF Mono caption2 | machine handle (raw) |

Serif name + mono handle + mono code tells a small story: a human-named
credential whose secret is machine output. The code uses
`contentTransition(.numericText())` and `minimumScaleFactor(0.6)` so 8-digit
codes still fit on small devices.

## Color tokens (obsidian palette)

| Token | Value | Use |
|-------|-------|-----|
| `ink`        | `#050507` | deepest void |
| `slab`       | `#16171C → #0A0B0E` gradient | polished card surface |
| `sheenLine`  | violet `#7E8BFF` → cyan `#5BE0D4`, fading at ends | top-edge light streak |
| `codeFill`   | white → `#CAD2DE` | engraved code glyphs |
| `accent`     | glacial `#7BC8F0` | copy flash, actions, fresh countdown |
| `warning`    | ember `#E8B05A` | countdown when ≤ 5s (stone cooling to molten) |
| `cardStroke` | white @ 7% | hairline rims |
| `background` | deep obsidian gradient | app background |

The accent is cool and restrained; it warms to ember only as a code expires —
a cooled-lava metaphor, the single temperature shift in the system.

## Card surface

A clean `RoundedRectangle` (radius 20) filled with `Theme.slab`, a `cardStroke`
hairline rim, a faded `sheenLine` across the top edge, and a soft float shadow.
Behind the content sits the oversized **icon block** (clipped to the card,
peeking from the top-left). Internal padding: `lg` all round. Metadata sits at
the top; the code is pushed `md` clear below it and embossed (`shadow black
55%, radius 0, y 1`) so it reads carved into the surface.

## Layout — the deck

`CardStack` lays the cards out with a single animated `VStack(spacing:)`:
collapsed spacing is negative (`peek − cardHeight`) so cards overlap; expanded
spacing is `md` so they spread. A toolbar control and a collapsed-card tap both
toggle the state with a spring. Delete is a long-press context menu (the
overlapping deck has no room for swipe).

## Countdown

One indicator only: a 20pt ring in the nameplate row's trailing edge. No numeric
seconds, no progress bar (both compete with the code / read as "utility"). It
drains and warms from glacial `accent` to ember `warning` at ≤ 5s. On rollover
the code re-etches with a brief blur pulse (`blur 5 → 0`, ease-out 0.5s).

## Interaction

- **Tap a card** → copies the code, success haptic, flashes the code `accent`,
  shows a "Copied" capsule for 1.5s.
- **Swipe a card** → delete.

## Principles checklist (apply to any new surface)

- [ ] Is the code (or primary value) the unmistakable focus?
- [ ] Is every supporting element demoted to metadata weight/color?
- [ ] Spacing from the scale only; generous vertical air?
- [ ] One slab surface + one facet sheen; no bespoke borders/shadows?
- [ ] Motion subtle and purposeful (no utility-style progress chrome)?
- [ ] Dark-first contrast holds; accent used sparingly, warmth reserved for expiry?
