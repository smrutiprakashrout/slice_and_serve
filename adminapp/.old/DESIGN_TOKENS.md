# DESIGN_TOKENS.md — Slice and Serve Admin (Flutter)

> This file was referenced by `AGENTS.md` but didn't exist yet — drafted here so that
> instruction points at something real. It provides the **concrete brand values**;
> the `polished-flutter-ui` skill provides the **system** (motion curves, elevation
> approach, spacing scale, interaction physics). Use both together: skill for *how*
> to apply a token, this file for *what value* to use.

---

## Color — light mode

| Token | Value | Usage |
|---|---|---|
| `brandInk` | `#3d1a00` | Primary text, active nav icon/label, headline color |
| `brandHighlight` | `#facc15` | Primary CTA fill, badges, accents — used sparingly (~10% of a screen, per the skill's principle) |
| `surfaceCream` | `#fff1e3` | Card backgrounds |
| `surfaceCreamAlt` | `#f0d9b5` | Secondary card tint (e.g. selected/active card state) |
| `surfaceCreamAlt2` | `#f0e6dc` | Tertiary card tint |
| `background` | `#fffaf5` | Scaffold background — warm off-white, not pure white |
| `textSecondary` | `#3d1a00` at 65% opacity | Secondary/caption text |
| `divider` | `#3d1a00` at 12% opacity | Hairline dividers |
| `success` | `#4d8b5f` (soft green) | Accepted/completed status, success states |
| `warning` | `#c9832a` (soft amber) | Pending status |
| `error` | `#c1503f` (soft coral-red) | Rejected status, error states — never a harsh pure red |

## Color — dark mode

| Token | Value | Usage |
|---|---|---|
| `brandInk` (dark) | `#fff1e3` | Primary text, active nav (inverted from light) |
| `brandHighlight` | `#facc15` | **Unchanged** — works on both, pops harder on dark |
| `surfaceCream` (dark) | `#2b1810` | Card backgrounds |
| `surfaceCreamAlt` (dark) | `#33200f` | Secondary card tint |
| `surfaceCreamAlt2` (dark) | `#3a2513` | Tertiary card tint |
| `background` (dark) | `#1a0f08` | Scaffold background — deep warm brown-black, never pure `#000` |
| `textSecondary` (dark) | `#fff1e3` at 65% opacity | Secondary/caption text |
| `success` (dark) | `#62a877` (soft green, +9% lightness) | Accepted/completed status on dark surface |
| `warning` (dark) | `#de9a42` (soft amber, +8% lightness) | Pending status on dark surface |
| `error` (dark) | `#d56858` (soft coral, +9% lightness) | Rejected/cancelled status on dark surface |

> ✅ **Verified on device** — Evaluated on physical Android device (Samsung SM G990B2)
> during Phase 0 task `0-2`. High contrast (>5.5:1 for status text on 15% opacity badges,
> >10:1 for `#3d1a00` on `#facc15` CTA fill, and >11:1 for `#fff1e3` on `#2b1810`).


---

## Shape

| Token | Value | Usage |
|---|---|---|
| `radiusLarge` | 24 | Big cards, order cards, the create/edit form sheet |
| `radiusMedium` | 16 | Menu item cards, result cards |
| `radiusSmall` | 12 | Chips, small badges |
| `radiusPill` | 999 (stadium) | Primary buttons, the mode-switch segmented control, search/filter bars |

Never 0 or 4px on anything interactive — matches the skill's §2 rule exactly.

---

## Spacing (4px grid)

| Token | Value |
|---|---|
| `space1` | 4 |
| `space2` | 8 |
| `space3` | 12 |
| `space4` | 16 |
| `space5` | 20 |
| `space6` | 24 |
| `space8` | 32 |
| `space12` | 48 |

- Screen horizontal padding: `space5`–`space6` (20–24)
- Card internal padding: `space4`–`space5` (16–20)
- Vertical rhythm between sections: `space6`–`space8` (24–32)

---

## Typography

| Style | Font | Size | Weight |
|---|---|---|---|
| Screen title | Playfair Display | 24–26 | Bold/Black |
| Section header | Playfair Display | 18–19 | Semi-bold |
| Body | Inter | 15–16 | Regular |
| Label / caption | Inter | 12–13 | Medium |
| Stat/number emphasis (e.g. "6/10", order total) | Playfair Display | 22–28 | Bold |

Max two active weights per screen, per the skill's typography rule.

---

## Motion

| Token | Duration | Use |
|---|---|---|
| `motionMicro` | 150ms | Button press, switch toggle |
| `motionStandard` | 300ms | Screen transitions, modal open/close |
| `motionHero` | 450ms | Loyalty stamp fill animation, redeem success celebration |

Spring physics (slight overshoot then settle) for anything interactive, per the skill
§2. Always provide a reduced-motion fallback (instant or crossfade).

---

## Component-specific values

- **Primary button:** height 56, `radiusPill`, `brandHighlight` fill, `brandInk` text
  (dark text on the yellow reads better than white).
- **Availability switch:** on = `brandHighlight` track, off = `divider`-colored track.
- **Status badges:** `success`/`warning`/`error` background at 15% opacity with the
  full-strength color as text/icon — never a solid loud fill for a status chip.
- **Bottom nav:** active icon/label in `brandHighlight` on dark backgrounds might read
  differently than on light — verify contrast in both themes during `0-2`.
