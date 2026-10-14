# TASKS.md — Slice and Serve Admin (Flutter)

**How to use this file**
Work top to bottom. Every task is ordered so its dependencies are already done.
Tick the box, commit with the task ID, move on. Never skip ahead.

- `[x]` done · `[~]` partially done · `[ ]` not started
- **Size:** S ≤ 1 h · M = few hours · L = day or more
- One task = one commit. Reference the ID in the commit message.
- **Every task is tagged `[A]` or `[B]`** (or `[Push]`/`[Launch]` for the final stages).
  Per `PROJECT_CONTEXT.md` §2: **every `[A]` task across every phase must be done and
  visually approved before any `[B]` task begins** — not just within one phase, across
  all of them. Stage A ends with a single deliberate checkpoint (below), not a
  phase-by-phase one.

**Progress:** 18 / 41 tasks complete (44%).

---

## Status at a glance

| Phase | What it delivers | Stage | Status |
|---|---|---|---|
| 0 | Project foundation & theme | A | ✅ 5/5 |
| 1A | Auth + shell UI (mock) | A | ✅ 2/2 |
| 2A | Menu tab UI (mock) | A | ✅ 4/4 |
| 3A | Loyalty scanner UI (mock) | A | ✅ 4/4 |
| 4A | Orders tab UI (mock) | A | 🔲 3/4 |
| 1B | Auth + shell wiring | B | 🔲 0/2 |
| 2B | Menu tab wiring | B | 🔲 0/5 |
| 3B | Loyalty wiring | B | 🔲 0/4 |
| 4B | Orders wiring | B | 🔲 0/3 |
| Push | Push notifications | Push | 🔲 0/4 |
| Launch | Polish, tests, release | Launch | 🔲 0/4 |

---

## Phase 0 — Foundation & theme [A]

Nothing visible ships here beyond a themed blank screen. Everything later depends on
it. **This entire phase is Stage A** — no networking code gets touched.

- [x] **0-1 · M ·** Scaffold the Flutter project (Android only). Add `google_fonts` and
      `flutter_riverpod` now (even though Stage A barely needs Riverpod — see
      `CODING_STANDARDS.md` §2 — having it in the project from the start avoids a
      later dependency-bump task). Do **not** add `dio`, `flutter_secure_storage`,
      `mobile_scanner`, `firebase_core`, `firebase_messaging`, or
      `flutter_local_notifications` yet — those are Stage B / Push additions; adding
      them now with nothing using them is a signal something's out of order. Enable
      `flutter_lints`, treat warnings as errors.
- [x] **0-2 · L ·** `theme/app_theme.dart` + ThemeExtensions: light and dark
      `ThemeData`, using the brand tokens in `PROJECT_CONTEXT.md` §5 as guided by the
      polished-flutter-ui skill's token system (§2 of the skill). Expose tokens as
      named constants too, not just baked into `ThemeData`. Wire `MaterialApp` to
      `ThemeMode.system`. Confirm switching the device/emulator's system theme flips
      the app. **Do this before any screen.**
- [x] **0-3 · M ·** Build 2-3 shared foundational widgets in `widgets/`: a brand
      button (tap-scale press interaction per the skill's §3), a brand card shell
      (rounded corners, themed surface), a confirmation dialog wrapper. Every screen
      below reuses these.
- [x] **0-4 · S ·** `mocks/` folder created (empty placeholder files fine for now —
      `mock_menu_items.dart`, `mock_orders.dart`, `mock_loyalty.dart`), so later Stage
      A tasks have a clear home. **Do not create `core/`, `services/`, or
      `providers/` yet** — those don't exist until Stage B (see `ARCHITECTURE.md` §0).
- [x] **0-5 · S ·** Empty placeholder files for `models/` and `screens/` per
      `ARCHITECTURE.md` §2's folder structure, so later tasks have a clear home.

> ✅ **Checkpoint:** an empty app that opens to a themed blank screen, correctly
> switching between light and dark mode. Confirm this looks right before building any
> actual screen.

---

## Phase 1A — Auth + shell UI (mock) [A]

- [x] **1A-1 · M ·** Login screen: username/password fields, submit button (using
      0-3's brand button), loading state on submit, inline error state. Mock the
      submit — any non-empty input navigates forward; a sentinel value (e.g. password
      `"fail"`) triggers the error state so it's reviewable. No forgot-password, no
      signup link — those screens don't exist, period (`PRD.md` A-2).
- [x] **1A-2 · M ·** `main_shell.dart`: bottom nav with Menu / Loyalty / Orders tabs,
      in that order, themed active/inactive states. A hardcoded badge number on the
      Orders tab icon for now, so its visual treatment is reviewable.

> ✅ **Checkpoint:** login → shell → tap between all three tabs (their content can
> still be empty placeholders at this point). Review specifically for feel — does
> tapping between tabs feel right, does the login transition feel right, in both
> themes.

---

## Phase 2A — Menu tab UI (mock) [A]

- [x] **2A-1 · M ·** `mocks/mock_menu_items.dart`: a hardcoded list covering
      available and unavailable items.
- [x] **2A-2 · L ·** Menu list screen: item cards with a placeholder image graphic
      (per `PRD.md` A-16 — there's never a real image, so this placeholder treatment
      is permanent, not temporary), name, price, availability toggle switch. Empty
      state and loading-skeleton state, both reachable via a mock trigger for review.
- [x] **2A-3 · L ·** Shared create/edit form (opened via "+" or tapping an item):
      name, subtitle, price, category picker (against a small hardcoded mock category
      list), veg/non-veg toggle, featured toggle. **No image field of any kind.**
- [x] **2A-4 · S ·** Delete confirmation dialog (using 0-3's confirmation wrapper) —
      doesn't persist anything yet, just the dialog and its visual flow.

> ✅ **Checkpoint:** the Menu tab is fully navigable and interactive on mock data —
> toggling availability, opening the form, "deleting" an item all feel right, in both
> light and dark mode.

---

## Phase 3A — Loyalty scanner UI (mock) [A]

- [x] **3A-1 · M ·** `mocks/mock_loyalty.dart`: mock customer/card data for both a
      stamp-scan scenario and a redeem-scan scenario.
- [x] **3A-2 · M ·** Mode switch (Add Stamp / Redeem) + a placeholder scanner-shaped
      view below it (real `mobile_scanner` is Stage B).
- [x] **3A-3 · L ·** Result card design — build BOTH the stamp-confirmation and
      redeem-confirmation variants, visually distinct (redeem should feel like a
      bigger, more deliberate action), triggered by a "simulate scan" mock button for
      review.
- [x] **3A-4 · M ·** Mode-mismatch error state (mock-triggerable) and the
      success-feedback state (visible + haptic wired in alongside it).

> ✅ **Checkpoint:** every Loyalty tab state — scanning placeholder, both result
> cards, the mismatch error, the success state — is reachable and reviewable via mock
> triggers, in both themes.

---

## Phase 4A — Orders tab UI (mock) [A]

- [x] **4A-1 · M ·** `mocks/mock_orders.dart`: a list covering all four statuses,
      both fulfillment types, and specifically a dine-in order with **no table
      number** (per `PRD.md` A-25 — this absence needs to look intentional).
- [x] **4A-2 · L ·** Segmented status control + order card list: fulfillment type,
      table number (gracefully absent), items, customer name, total, relative
      timestamp.
- [x] **4A-3 · M ·** Accept/Reject/Complete action buttons, correctly appearing only
      for their valid status (pending→Accept/Reject, accepted→Complete,
      completed/rejected→none at all). Reject routes through 0-3's confirmation
      dialog.
- [ ] **4A-4 · S ·** Pull-to-refresh gesture wired visually (no real fetch behind it
      yet).

> ✅ **Checkpoint — Stage A complete, all phases.** Every screen, every state, both
> themes, reviewed and genuinely approved by you on a real device or emulator — not
> just "technically present." **Do not start any `[B]` task until this is satisfying.**
> This is the one hard gate in this entire file that matters most.

---

## Phase 1B — Auth + shell wiring [B]

Each task here references the exact endpoint contract in `ARCHITECTURE.md` §4 — look
shapes up there, don't re-derive them.

- [ ] **1B-1 · M ·** Networking foundation: `core/api_client.dart` (dio instance, base
      URL config for dev/prod, JWT-attaching interceptor, central 401 → clear token →
      navigate to login), `core/secure_store.dart` (`flutter_secure_storage`
      wrapper), `core/result.dart` (the `Result<T>` success/failure wrapper).
- [ ] **1B-2 · M ·** Wire the login screen (1A-1) to `POST /api/admin/login`. Store
      the real JWT, replace mock success/fail logic with real responses, reusing the
      exact error UI Stage A already built. Add session-restore on cold start (valid
      token in secure storage → skip straight to the shell).

> ✅ **Checkpoint:** log in for real, confirm the session survives an app restart.

---

## Phase 2B — Menu tab wiring [B]

- [ ] **2B-1 · M ·** Wire the menu list (2A-2) to `GET /api/menu`. Delete
      `mocks/mock_menu_items.dart` once confirmed working.
- [ ] **2B-2 · M ·** Wire the availability toggle to
      `PATCH /api/menu/:id/availability`, optimistic with rollback on failure.
- [ ] **2B-3 · L ·** Wire the create/edit form (2A-3) to `POST`/`PUT /api/menu`,
      surfacing real validation errors inline.
- [ ] **2B-4 · S ·** Wire delete (2A-4) to `DELETE /api/menu/:id`.
- [ ] **2B-5 · S ·** Wire the category picker to `GET /api/categories`.

> ✅ **Checkpoint:** toggle a real item's availability, confirm it changes on the
> customer web app.

---

## Phase 3B — Loyalty wiring [B]

- [ ] **3B-1 · L ·** Real `mobile_scanner` integration replacing the 3A-2 placeholder
      view.
- [ ] **3B-2 · M ·** Wire a successful scan to `GET /api/loyalty/scan/:token`; render
      3A-3's result cards with real data; enforce the mode-mismatch guard (3A-4) using
      the real `action` field.
- [ ] **3B-3 · M ·** Wire stamp confirmation to
      `POST /api/loyalty/:customerId/stamp`, and redeem confirmation to
      `POST /api/loyalty/:customerId/redeem` — redeem only ever offered when the scan
      result's card shows `rewardReady: true`.
- [ ] **3B-4 · S ·** Delete `mocks/mock_loyalty.dart`.

> ✅ **Checkpoint:** scan a real customer's stamp QR, confirm their card visibly
> updates on the customer web app within a few seconds (the web app polls — see its
> own `ARCHITECTURE.md` §5.8, no real-time push exists on that side).

---

## Phase 4B — Orders wiring [B]

- [ ] **4B-1 · M ·** Wire the orders list (4A-2) to `GET /api/orders?status=`,
      refetched on pull-to-refresh (4A-4) and tab navigation. Delete
      `mocks/mock_orders.dart`.
- [ ] **4B-2 · M ·** Wire Accept/Reject/Complete (4A-3) to their respective
      `PATCH /api/orders/:id/...` endpoints. A 409 (stale list, shouldn't normally
      happen since the UI only offers legal actions) shows a clear error and
      refreshes the list.
- [ ] **4B-3 · S ·** Wire the pending-count badge (1A-2) to a real count.

> ✅ **Checkpoint — Stage B complete.** Log in for real, manage the real menu, scan a
> real loyalty QR, and work real orders — all reflected on the customer web app within
> a few seconds.

---

## Push notification stage [Push]

References the Next.js repo's own `TASKS.md` Phase 9 for the backend-side half
(Firebase project creation, `POST /api/admin/fcm-token` existing, the server sending
FCM on new orders) — those are already-tracked backend tasks, not repeated here.

- [ ] **Push-1 · M ·** `notification_service.dart`: request permission, obtain the FCM
      token, register it via `POST /api/admin/fcm-token` on login and on token
      refresh.
- [ ] **Push-2 · L ·** Android custom notification channel: high importance, raw
      sound asset, created at app startup — before any notification can arrive.
- [ ] **Push-3 · M ·** Handle foreground, background, and terminated states; deep-link
      a tap into the Orders tab, Pending filter.
- [ ] **Push-4 · M ·** Test on a **real device**, app killed, screen off, under
      battery optimization. Emulators are unreliable. Document any OEM battery
      settings the owner needs to disable.

---

## Launch [Launch]

- [ ] **Launch-1 · M ·** Widget tests: login, availability toggle, order action
      buttons, loyalty mode-mismatch guard (per `CODING_STANDARDS.md` §6).
- [ ] **Launch-2 · M ·** Full visual & interaction polish pass — every screen against
      the polished-flutter-ui checklist (skill §7), light + dark, large text,
      reduced motion.
- [ ] **Launch-3 · M ·** Generate the release keystore, `flutter build apk --release`,
      sideload onto the owner's device.
- [ ] **Launch-4 · M ·** Run the full acceptance check from `PRD.md` §5, end to end,
      on the real device, alongside the customer web app. Write a one-page handover
      note for the owner (how to log in, what to do if push stops).

---

## Dependency map

```
Phase 0 (foundation + theme)
  └─► Phase 1A (auth + shell UI)
        ├─► Phase 2A (menu UI)
        ├─► Phase 3A (loyalty UI)
        └─► Phase 4A (orders UI)
              │
              ▼
        ═══ STAGE A CHECKPOINT — must be approved before any [B] task ═══
              │
              ▼
        Phase 1B (auth wiring)
              ├─► Phase 2B (menu wiring)
              ├─► Phase 3B (loyalty wiring)
              └─► Phase 4B (orders wiring)
                    └─► Push stage ──► Launch
```

**Hard gates**
1. **0-2 (theme)** must be finished before any screen.
2. **The Stage A checkpoint** — every `[A]` task across all four phases, approved —
   before any `[B]` task starts. This is the gate that matters most; it's the entire
   reason this file is structured this way.
3. **Push-2 + Push-4 (notifications on a real device)** are the final quality gate
   before Launch.

---

## Suggested pacing

| Days | Phases | You will be able to... |
|---|---|---|
| 1 | 0 | See a themed blank screen, both light and dark |
| 2 | 1A | Log in (mock) and see the three-tab shell |
| 3 | 2A | Click through the full menu UI on fake data |
| 4 | 3A | Click through the full loyalty scanner UI on fake data |
| 5 | 4A | Click through the full orders UI on fake data — **Stage A review happens here** |
| 6 | 1B, 2B | Log in for real, manage the real menu from the phone |
| 7 | 3B | Scan real stamps and redeem real rewards |
| 8 | 4B | Accept / reject / complete real orders |
| 9–10 | Push | Receive custom-sound push when the app is killed |
| 11 | Launch | Signed APK + handover note ready |
