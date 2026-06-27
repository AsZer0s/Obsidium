# Obsidium Design System v1

The visual language: **dark-first, minimal chrome, security-grade air, and
monospaced digits as the identity.** One rule governs everything —

> Each token is a cryptographic card where the **code is the only hero**.

All tokens live in `Obsidium/UI/Theme.swift`. This document is the spec; the
code is the source of truth.

## Spacing scale

A single 4-based scale. Use these, never raw numbers.

| Token | Value | Typical use |
|-------|-------|-------------|
| `xs`  | 4  | tight metadata gaps |
| `sm`  | 8  | inline gaps, chip padding |
| `md`  | 12 | — |
| `lg`  | 16 | card horizontal padding, metadata→code gap |
| `xl`  | 24 | card vertical padding ("air"), screen padding |
| `xxl` | 32 | large empty-state breathing room |

## Type scale

The code dominates; everything else reads as metadata.

| Token | Font | Role |
|-------|------|------|
| `code`   | system 48, semibold, **monospaced**, `tracking(8)` | the hero |
| `issuer` | caption, `.secondary` | service name (quiet) |
| `label`  | caption2, `.tertiary` | account name (quieter) |

The code uses `.contentTransition(.numericText())` so digits roll, plus a
`minimumScaleFactor(0.6)` so 8-digit codes still fit on small devices.

## Color tokens (dark palette)

| Token | Value | Use |
|-------|-------|-----|
| `accent`     | mint `#66D1B3` | code-on-copy, ring, primary actions |
| `warning`    | coral `#F58073` | countdown ring when ≤ 5s remain |
| `cardStroke` | white @ 8% | hairline card / chip borders |
| `background` | obsidian gradient (near-black, faint cool tint) | app background |

The accent is intentionally **desaturated** — "secure," not loud. The prominent
button pairs it with black text for contrast.

## Card style

One reusable surface: `.glassCard()` (a `View` extension in `Theme.swift`).

- `.ultraThinMaterial` fill, `22pt` continuous-corner radius
- `cardStroke` hairline border
- soft float: `shadow(black 28%, radius 10, y 5)`
- internal padding: `lg` horizontal, `xl` vertical (Apple-style air)
- metadata sits at the top; the code is pushed `lg` clear below it

## Countdown

Deliberately minimal — **one** indicator: a 20pt ring in the card's top-right.
No numeric seconds, no progress bar (both compete with the code / read as
"utility"). The ring drains and turns `warning` coral at ≤ 5s.

On each rollover the code "resolves into focus" via a brief blur pulse
(`blur 5 → 0`, ease-out 0.5s) — the calm, Apple-like substitute for a bar.

## Interaction

- **Tap a card** → copies the code, fires a success haptic, flashes the code
  `accent` and shows a "Copied" capsule for 1.5s.
- **Swipe a card** → delete.

## Principles checklist (apply to any new surface)

- [ ] Is the code (or the primary value) the unmistakable focus?
- [ ] Is every supporting element demoted to metadata weight/color?
- [ ] Spacing from the scale only; generous vertical air?
- [ ] One glass card style; no bespoke borders/shadows?
- [ ] Motion is subtle and purposeful (no utility-style progress chrome)?
- [ ] Dark-first contrast holds; accent used sparingly?
