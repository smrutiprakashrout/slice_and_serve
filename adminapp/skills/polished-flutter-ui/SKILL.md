---
name: polished-flutter-ui
description: Create exceptionally clean, professional, elegant, brand-like polished Flutter mobile UIs with refined soft aesthetics, systematic design tokens, expressive yet restrained motion, strong hierarchy, thumb-zone UX, and delightful purposeful micro-interactions. Use for any Flutter app screens, onboarding, loyalty/rewards, fintech, travel, food, consumer, or productivity apps that must feel premium and lovable on first launch.
---

# Polished Flutter UI — Elite Design System

Produce Flutter interfaces that feel like a high-end product from a top design studio. Every screen must be clean, elegant, brand-consistent, and interactive in a way that feels alive but never noisy. First-time users should immediately trust and enjoy the experience.

This system synthesizes the soft modern aesthetic of leading consumer apps with 2025–2026 principles from Apple Liquid Glass (hierarchy, depth, content focus) and Material 3 Expressive (purposeful shape, color, typography, and motion to guide attention).

## 1. Foundational Design Principles

1. **Clarity first, expression second**  
   Every visual decision must improve understanding or reduce cognitive load. Beauty without clarity is decoration.

2. **Hierarchy through depth and containment**  
   Content lives on the base layer. Interactive controls and navigation float above it with clear separation (inspired by Liquid Glass functional layer). Use soft elevation, subtle surface tint, or restrained translucency only for functional chrome.

3. **One primary action per screen**  
   Make the main CTA the most prominent element via size, color, weight, and position (thumb zone).

4. **Brand-like consistency**  
   Every corner radius, spacing, elevation, motion curve, and icon style must come from the same token system. No one-off values.

5. **Motion as communication**  
   Animation exists only to confirm state, show relationships, or provide satisfying feedback. Never decorate.

6. **Thumb-zone and accessibility by default**  
   Primary interactive elements live in the lower 40% of the screen. Minimum 48 dp touch targets. Full WCAG AA contrast. Respect `prefers-reduced-motion`.

7. **Soft premium feel**  
   Rounded forms, diffused soft shadows or surface tints, restrained gradients, high-quality imagery or soft 3D-style icons, generous breathing room.

## 2. Design Tokens (Single Source of Truth)

Define these once in `ThemeData` + extensions and never hard-code values in widgets.

### Color
- Seed-based Material 3 `ColorScheme` refined for softness.
- Light mode background: near-white or warm soft gray (#F7F8FA / #FAFAF7).
- Dark mode background: deep rich charcoal or forest-tinted black (never pure #000).
- Surfaces: slightly elevated from background (light: pure white or soft tint; dark: lighter surface with subtle tint).
- Primary accent: soft but confident (lime-yellow, soft teal, coral, muted mint). Used sparingly (≈10%).
- Gradients: very soft linear or subtle on hero cards and primary CTAs only. Low opacity.
- Semantic: soft success green, soft amber warning, soft coral error.
- Text: high-contrast primary, secondary at 60–70% opacity.

### Shape
- Large cards / containers: 20–24 px
- Medium components: 16 px
- Small chips / buttons: 12–14 px
- Search bars, primary CTAs, progress pills: full stadium / 999
- Never sharp 0 or 4 px corners on interactive elements.

### Elevation & Depth
- Prefer Material 3 surface tint + low elevation (0–3) over heavy drop shadows.
- Soft diffused shadow only when needed for separation.
- Dark mode: use elevated surfaces instead of strong shadows.
- Functional chrome (nav bars, floating controls) may use restrained translucency or blur only if legibility remains excellent.

### Spacing
- 4 px base grid.
- Screen horizontal padding: 20–24 px.
- Card internal: 16–20 px.
- Vertical rhythm: 8 / 12 / 16 / 24 / 32 / 48.
- Generous whitespace around heroes and between sections. Never cramped.

### Typography
Clean geometric sans (Plus Jakarta Sans, Manrope, Outfit, Inter, or SF Pro equivalent).

Scale (approximate):
- Display / Hero: 28–34, semi-bold or bold
- Screen title: 22–26, semi-bold
- Section: 17–19, semi-bold
- Body: 15–16, regular
- Label / Caption: 12–13, medium
- Micro: 11

Rules:
- Strong size + weight contrast for hierarchy.
- Emphasized variants for key actions and headlines (M3 Expressive tactic).
- Personalized greetings use friendly medium weight.
- Maximum two active weights per screen.
- Dynamic type support where practical.

### Motion Tokens
- Micro (button press, toggle): 120–200 ms
- Standard transitions: 250–350 ms
- Hero / significant state: up to 450–500 ms max
- Prefer spring physics (slight overshoot then settle) for interactive elements.
- Ease-out for entrances, ease-in for exits.
- Always provide reduced-motion fallback (crossfade or instant).

## 3. Interaction & Micro-Interaction System

Every interactive element must give clear, immediate feedback.

### Press / Tap
- Scale to 0.97–0.98 + slight opacity or color shift.
- Optional soft haptic (light impact).
- Release returns with spring.

### State Changes
- Toggle, checkbox, switch: smooth morph or color fill with spring.
- Progress bars / stamps: animate fill smoothly.
- Success: brief checkmark scale + optional confetti or subtle celebration (keep under 600 ms).
- Error: gentle shake or soft red pulse + clear recovery action.

### Navigation
- Forward: horizontal push or shared-axis.
- Modal / sheet: slide up from bottom with soft spring.
- Back: reverse of forward.
- Tab switch: crossfade or subtle slide, never jarring.

### Lists & Cards
- Press: subtle scale + elevation lift.
- Swipe actions: reveal with spring and clear icon + label.
- Reorder or expand: smooth height animation.

### Loading & Empty
- Skeleton shimmer or soft morphing indicator (never blank screen).
- Empty states: friendly illustration + one clear action + short guidance text.
- Pull-to-refresh: elegant indicator that matches brand motion.

### Redemption / Critical Flows
- Large QR / barcode centered with clear instruction.
- Success confirmation with satisfying micro-animation and next-step CTA.
- Always offer alternative (NFC, manual code).

## 4. Component Recipes

### Primary Button
- Height 52–56 dp, full pill or 16–20 radius.
- Soft gradient or solid accent fill.
- White or high-contrast text, medium weight.
- Press scale + optional haptic.
- Loading state: replace label with compact indicator, keep size.

### Secondary / Tertiary
- Soft filled neutral or outlined.
- Same height and radius language.
- Lower visual weight.

### Cards
- 20–24 radius, soft surface, low elevation or surface tint.
- Internal padding 16–20.
- Optional soft gradient or high-quality image with dark scrim for text.
- Trailing chevron or progress indicator when interactive.
- Press feedback mandatory.

### Search
- Full pill, soft fill, leading icon, optional trailing clear/filter.
- Focus: subtle border or elevation lift.

### Bottom Navigation
- 3–5 items max.
- Soft elevated or translucent surface.
- Active: filled icon + accent or soft pill background.
- Optional floating center action with accent treatment.
- Labels preferred for clarity.

### Progress / Loyalty
- Circular stamps: filled = accent or brand icon, empty = soft dashed or muted outline.
- Linear progress: rounded track, accent fill, animate.
- Reward cards: soft vibrant gradient, clear value proposition, QR when redeeming.
- Always show “X of Y” or visual progress.

### Lists
- Icon / avatar + title + subtitle + trailing.
- Consistent 12–16 gap.
- Soft dividers or card separation.
- Expandable sections with smooth height animation.

### Onboarding
- Soft full-bleed or centered illustration.
- Short friendly headline + 1–2 lines body.
- Primary CTA + Skip.
- Progress dots.
- Value before signup whenever possible.

### Forms
- Soft filled or outlined, consistent radius.
- Clear labels, generous targets.
- Inline validation with soft colors and helpful microcopy.
- Keyboard-aware scrolling.

## 5. Screen-Level Composition Rules

- Status bar and home indicator respected (SafeArea).
- One clear visual focus and one primary action.
- Thumb-zone placement for main CTAs and navigation.
- Breathing room: never pack elements tightly.
- Personalized greeting on home when user is known.
- Progress always visible for goal-oriented features (loyalty, onboarding, multi-step).
- Consistent back / close affordance.
- Dark mode is a first-class, intentional design — not an inversion.

## 6. Flutter Implementation Guidelines

- `useMaterial3: true` with carefully tuned `ColorScheme.fromSeed` + custom refinements.
- Create `ThemeExtension`s for radii, spacing, motion, and brand-specific tokens.
- Prefer `Card`, `FilledButton`, `NavigationBar` etc., then restyle via theme rather than one-off containers when possible.
- For soft gradients on buttons/cards: `Container` + `InkWell` / `Material` or lightweight packages, but keep performance high.
- Spring animations: use `SpringSimulation` or packages that expose physics (or `AnimatedContainer` + curves carefully).
- Images: high quality, correctly cropped, with scrims when text overlays.
- Icons: one consistent soft/rounded family (size 20–24 list, 28–32 cards).
- Always test light + dark + large text + reduced motion.
- Performance: limit simultaneous blurs, use `RepaintBoundary` for complex effects, target 60/120 fps.

## 7. Brand-Like Consistency Checklist (Run on Every Screen)

- [ ] All radii, spacing, elevations come from tokens
- [ ] Primary action is visually dominant and in thumb zone
- [ ] Hierarchy is instantly clear (size, weight, color, containment)
- [ ] Motion is purposeful and uses system curves
- [ ] Touch targets ≥ 48 dp
- [ ] Contrast meets AA
- [ ] Light and dark both feel intentional
- [ ] Empty / loading / error states are designed and friendly
- [ ] No visual noise or competing elements
- [ ] Feels premium, calm, and trustworthy on first glance

## 8. When References Are Missing

Apply the same soft premium language, token system, hierarchy, and interaction rules. Prefer progressive disclosure, clear containment, visual progress, and high-quality imagery or soft illustrations for emotional moments. Keep loyalty, rewards, financial, and critical flows especially clear and confidence-building.

The goal is not to copy any single app. The goal is to produce interfaces that feel like they belong to a carefully crafted, high-end product that users love from the first second.
