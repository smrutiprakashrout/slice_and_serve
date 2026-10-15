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

**Progress:** 19 / 51 tasks complete (~37%). All original Stage A screens built and
approved; two post-review revisions (Orders restructure, splash screen) and a new
Settings phase added before Stage B begins.

---

## Status at a glance

| Phase | What it delivers | Stage | Status |
|---|---|---|---|
| 0 | Project foundation & theme | A | ✅ 5/5 |
| 1A | Auth + shell UI (mock) | A | ✅ 2/2 |
| 2A | Menu tab UI (mock) | A | ✅ 4/4 |
| 3A | Loyalty scanner UI (mock) | A | ✅ 4/4 |
| 4A | Orders tab UI (mock) + revisions + splash | A | 🟡 4/6 |
| 5A | Settings tab (new, local-only) | A | 🔲 0/4 |
| Net | Local dev networking setup | Net | 🔲 0/4 |
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
      ⚠️ **Superseded by 4A-5 below** — originally built with 4 segments
      (Pending/Accepted/Completed/Rejected); revised down to 3.
- [x] **4A-3 · M ·** Accept/Reject/Complete action buttons, correctly appearing only
      for their valid status (pending→Accept/Reject, accepted→Complete,
      completed/rejected→none at all). Reject routes through 0-3's confirmation
      dialog.
      ⚠️ **Superseded by 4A-5 below** — the Reject *action* is unchanged, but there's
      no longer a Rejected segment to view the result in.
- [x] **4A-4 · S ·** Pull-to-refresh gesture wired visually (no real fetch behind it
      yet).

### Post-review revisions — decided after the Stage A walkthrough

- [ ] **4A-5 · M · [A] ·** Revise the Orders tab per the post-Stage-A-review decision:
      - Collapse the segmented control from four segments to **three: Pending,
        Preparing, Completed.**
      - **"Preparing" is a display-only rename of the existing `accepted` status.**
        The underlying value stored on the Order model and everywhere it's referenced
        in code stays `"accepted"` — only the label shown in the segmented control and
        on order cards changes to "Preparing". This is a fixed backend enum
        (`PROJECT_CONTEXT.md` §4) and is not being changed at the data level, only
        the UI layer. Do this via a small display-label mapping function
        (`accepted` → "Preparing" for display), not by renaming the enum value itself.
      - **Remove the Rejected segment entirely.** There is no tab/segment to browse
        rejected orders. The **Reject action itself is unchanged** — it still exists
        on pending order cards, still requires the 0-3 confirmation dialog, still
        transitions the order's status to `rejected`. The only change: once an order
        is rejected, it simply leaves the visible list (filtered out), since none of
        the three segments show it.
      - The **Accept button's label stays "Accept"** (it's the verb for the action);
        only the segment/tab header and the order card's status indicator display
        "Preparing" once that action has been taken. Don't rename the button itself.
      - Update `order_card.dart`'s status-color mapping (warning/success/error from
        `DESIGN_TOKENS.md`) to the 3-state set — a rejected order's error-color
        treatment is now moot since rejected orders are never displayed, but leave the
        color mapping logic intact in case that changes later; just confirm nothing
        crashes if a rejected order is ever passed to it defensively.
- [x] **4A-6 · M · [A] ·** Custom splash screen: add `flutter_native_splash` as a dev
      dependency, configure it with the brand background token from
      `DESIGN_TOKENS.md` and your logo/wordmark image. If no logo file exists yet, use
      a simple Playfair Display wordmark rendered on the brand background as a
      placeholder splash, easily swappable once a real logo exists. Generate the splash
      assets and confirm it displays correctly on cold start, in both light and dark
      system settings (flutter_native_splash supports separate light/dark
      configuration — use it, don't just pick one).

> ✅ **Checkpoint — Phase 4A (revised) complete.** Orders tab is down to 3 segments
> with "Preparing" as a display label, Reject still works but isn't browsable after
> the fact, and the app has a real splash screen. Move on to Phase 5A next — Stage A
> isn't fully done until Settings exists too.

---

## Phase 5A — Settings tab UI (mock + local-only) [A]

New 4th bottom-nav tab, decided after the Stage A review. **Note:** the theme picker
uses `shared_preferences` for on-device persistence — this is **local storage, not a
backend API call**, so it doesn't violate the Stage A/B split (`PROJECT_CONTEXT.md`
§2) and is fine to build for real right now, not mocked.

- [x] **5A-1 · M · [A] ·** Add a 4th bottom-nav tab, **Settings**, after Orders (order:
      Menu, Loyalty, Orders, Settings). Build `screens/settings/settings_screen.dart`
      as a simple list of sections: Theme, About, Report a Bug — scaffold only in this
      task, each section's real content comes in 5A-2 through 5A-4.
- [x] **5A-2 · M · [A] ·** Theme picker: Light / Dark / System, radio-style selection.
      Add `shared_preferences` as a dependency. Default is **Light**. Selecting an
      option immediately updates `MaterialApp`'s `themeMode` (via a simple
      `ChangeNotifier`, `StateProvider`, or similar — your call, doesn't need full
      Riverpod machinery for something this small) AND persists the choice to
      `shared_preferences`, read back on app launch so the preference survives a
      restart.
- [x] **5A-3 · S · [A] ·** Version display + About + "Check for update": add
      `package_info_plus`, display the app version from it. "Check for update" is a
      **static placeholder for v1** — tapping it can show a simple "You're on the
      latest version" message or similar; no real update-check mechanism, per the
      decision made when this was scoped. About section is static brand/app
      description text.
- [x] **5A-4 · S · [A] ·** "Report a bug": tapping it shows a static message with your
      contact info (no email intent, no form — per the decision made when this was
      scoped). Keep it simple: a dialog or inline text, brand-styled.

> ✅ **Checkpoint — Stage A (all phases, fully revised) complete.** Walk through the
> whole app again — all four tabs, both themes, the splash screen, the revised Orders
> segments — before touching anything in Phase Net or Phase 1B.

---

## Phase Net — Local dev networking setup [Net]

Not Flutter app code — environment/infrastructure verification, needed because the
backend is currently running locally (not deployed) and the Flutter app runs on a
physical device that can't reach a laptop's `localhost` directly. **Everything in this
phase is temporary, dev-only setup** — it gets replaced once the backend is deployed
to production (Vercel, per the web app's own `ARCHITECTURE.md` §8); don't treat any IP
or config here as permanent.

- [x] **Net-1 · S ·** Start the Next.js dev server bound to `0.0.0.0` instead of the
      default localhost-only binding (e.g. `next dev -H 0.0.0.0`, or set `hostname` in
      the relevant config/script), so it's reachable from other devices on the
      Tailscale network, not just the laptop itself.
- [x] **Net-2 · S ·** Open the dev server's port (default 3000, confirm whichever port
      it's actually running on) on the laptop's firewall for the Tailscale interface
      specifically — not a blanket "allow all inbound," just the Tailscale adapter.
- [x] **Net-3 · S ·** From the phone's browser (connected via Tailscale, not the same
      Wi-Fi necessarily), hit `http://<laptop-tailscale-ip>:3000/api/health` — the
      already-built health-check endpoint from the web app's own `TASKS.md` (P5-12).
      Confirm you get back `{ "status": "ok", ... }`. This proves connectivity before
      any Flutter networking code gets written against it.
- [x] **Net-4 · S ·** Note the laptop's Tailscale IP somewhere durable (not just
      memory) — it's what task `1B-1` will put in `core/constants.dart` as the dev API
      base URL. Flag clearly in that file (a code comment is enough) that this value
      is temporary and must be swapped for the real production URL before `Launch-3`.

> ✅ **Checkpoint:** `/api/health` responds correctly from the phone's browser over
> Tailscale. Only once this works should `1B-1` begin — Stage B's very first task
> immediately needs working connectivity to test against.

---

## Phase 1B — Auth + shell wiring [B]

Each task here references the exact endpoint contract in `ARCHITECTURE.md` §4 — look
shapes up there, don't re-derive them.

- [x] **1B-1 · M ·** Networking foundation: `core/api_client.dart` (dio instance, base
      URL config for dev/prod, JWT-attaching interceptor, central 401 → clear token →
      navigate to login), `core/secure_store.dart` (`flutter_secure_storage`
      wrapper), `core/result.dart` (the `Result<T>` success/failure wrapper).
- [x] **1B-2 · M ·** Wire the login screen (1A-1) to `POST /api/admin/login`. Store
      the real JWT, replace mock success/fail logic with real responses, reusing the
      exact error UI Stage A already built. Add session-restore on cold start (valid
      token in secure storage → skip straight to the shell).

> ✅ **Checkpoint:** log in for real, confirm the session survives an app restart.

---

## Phase 2B — Menu tab wiring [B]

- [x] **2B-1 · M ·** Wire the menu list (2A-2) to `GET /api/menu`. Delete
      `mocks/mock_menu_items.dart` once confirmed working.
- [x] **2B-2 · M ·** Wire the availability toggle to
      `PATCH /api/menu/:id/availability`, optimistic with rollback on failure.
- [x] **2B-3 · L ·** Wire the create/edit form (2A-3) to `POST`/`PUT /api/menu`,
      surfacing real validation errors inline.
- [x] **2B-4 · S ·** Wire delete (2A-4) to `DELETE /api/menu/:id`.
- [x] **2B-5 · S ·** Wire the category picker to `GET /api/categories`.

> ✅ **Checkpoint:** toggle a real item's availability, confirm it changes on the
> customer web app.

---

## Phase 3B — Loyalty wiring [B]

- [x] **3B-1 · L ·** Real `mobile_scanner` integration replacing the 3A-2 placeholder
      view.
- [x] **3B-2 · M ·** Wire a successful scan to `GET /api/loyalty/scan/:token`; render
      3A-3's result cards with real data; enforce the mode-mismatch guard (3A-4) using
      the real `action` field.
- [x] **3B-3 · M ·** Wire stamp confirmation to
      `POST /api/loyalty/:customerId/stamp`, and redeem confirmation to
      `POST /api/loyalty/:customerId/redeem` — redeem only ever offered when the scan
      result's card shows `rewardReady: true`.
- [x] **3B-4 · S ·** Delete `mocks/mock_loyalty.dart`.

> ✅ **Checkpoint:** scan a real customer's stamp QR, confirm their card visibly
> updates on the customer web app within a few seconds (the web app polls — see its
> own `ARCHITECTURE.md` §5.8, no real-time push exists on that side).

---

## Phase 4B — Orders wiring [B]

- [x] **4B-1 · M ·** Wire the orders list (4A-2) to `GET /api/orders?status=`,
      refetched on pull-to-refresh (4A-4) and tab navigation. Delete
      `mocks/mock_orders.dart`.
- [x] **4B-2 · M ·** Wire Accept/Reject/Complete (4A-3) to their respective
      `PATCH /api/orders/:id/...` endpoints. A 409 (stale list, shouldn't normally
      happen since the UI only offers legal actions) shows a clear error and
      refreshes the list.
- [x] **4B-3 · S ·** Wire the pending-count badge (1A-2) to a real count.

> ✅ **Checkpoint — Stage B complete.** Log in for real, manage the real menu, scan a
> real loyalty QR, and work real orders — all reflected on the customer web app within
> a few seconds.

---

## Push notification stage [Push]

References the Next.js repo's own `TASKS.md` Phase 9 for the backend-side half
(Firebase project creation, `POST /api/admin/fcm-token` existing, the server sending
FCM on new orders) — those are already-tracked backend tasks, not repeated here.

- [x] **Push-1 · M ·** `notification_service.dart`: request permission, obtain the FCM
      token, register it via `POST /api/admin/fcm-token` on login and on token
      refresh.
- [x] **Push-2 · L ·** Android custom notification channel: high importance, raw
      sound asset, created at app startup — before any notification can arrive.
- [x] **Push-3 · M ·** Handle foreground, background, and terminated states; deep-link
      a tap into the Orders tab, Pending filter.
- [x] **Push-4 · M ·** Test on a **real device**, app killed, screen off, under
      battery optimization. Emulators are unreliable. Document any OEM battery
      settings the owner needs to disable.

---

## Launch [Launch]

- [x] **Launch-1 · M ·** Widget tests: login, availability toggle, order action
      buttons, loyalty mode-mismatch guard (per `CODING_STANDARDS.md` §6).
- [x] **Launch-2 · M ·** Full visual & interaction polish pass — every screen against
      the polished-flutter-ui checklist (skill §7), light + dark, large text,
      reduced motion.
- [x] **Launch-3 · M ·** Generate the release keystore, `flutter build apk --release`,
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
        └─► Phase 4A (orders UI) ──► 4A-5, 4A-6 (revisions: 3 segments, splash)
              │
              ▼
        Phase 5A (Settings — new 4th tab, local-only)
              │
              ▼
        ═══ STAGE A CHECKPOINT — must be approved before any [B] task ═══
              │
              ▼
        Phase Net (Tailscale dev networking — verify /api/health reachable)
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
2. **The Stage A checkpoint** — every `[A]` task across all phases (including the 4A
   revisions and Phase 5A) approved — before any `[B]` task starts.
3. **Phase Net** — `/api/health` must respond over Tailscale before `1B-1` begins;
   Stage B's first task needs working connectivity to test against, and this setup is
   dev-only, replaced by a real production URL before `Launch-3`.
4. **Push-2 + Push-4 (notifications on a real device)** are the final quality gate
   before Launch.

---

## Suggested pacing

| Days | Phases | You will be able to... |
|---|---|---|
| 1 | 0 | See a themed blank screen, both light and dark |
| 2 | 1A | Log in (mock) and see the four-tab shell |
| 3 | 2A | Click through the full menu UI on fake data |
| 4 | 3A | Click through the full loyalty scanner UI on fake data |
| 5 | 4A | Click through the full orders UI on fake data |
| 5.5 | 4A-5, 4A-6, 5A | See the revised 3-segment Orders tab, the splash screen, and the new Settings tab — **Stage A review happens here, at the very end** |
| 6 | Net | Confirm `/api/health` reachable from the phone over Tailscale |
| 7 | 1B, 2B | Log in for real, manage the real menu from the phone |
| 8 | 3B | Scan real stamps and redeem real rewards |
| 9 | 4B | Accept / reject / complete real orders |
| 10–11 | Push | Receive custom-sound push when the app is killed |
| 12 | Launch | Signed APK + handover note ready — including swapping the dev Tailscale URL for the real production URL |
