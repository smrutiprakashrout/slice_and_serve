# TASKS.md — Slice and Serve Build Roadmap

**How to use this:** work top to bottom. Every task is ordered so that its dependencies
are already done. Tick a box, commit, move on. Never skip ahead — the ordering is the
whole point.

- `[x]` done · `[~]` partially done · `[ ]` not started
- **Size:** S = under an hour · M = a few hours · L = a day or more
- Do **one task per commit**, referencing the ID (see `CODING_STANDARDS.md` §3).

**Progress:** ~53 / 88 tasks complete (~60%). Phases 1–6 done. Phase 7 rebuilt around
polling instead of Firestore (see `ARCHITECTURE.md` §5.8) — not started yet. *(Total
task count: 92 → 91 after P3-10 was cut → 88 after Phase 7 shrank from 7 tasks to 3 and
Phase 9 gained one — creating the Firebase project, deferred from the old Phase 7.)*

---

## Status at a glance

| Phase | What it delivers | Status |
|---|---|---|
| 0 | Repo hygiene — make the build green and safe | 🟡 partial |
| 1 | Database foundation — connection, models, seed | ✅ 8/8 |
| 2 | Admin auth — unblocks every admin endpoint | ✅ 5/5 |
| 3 | Menu end-to-end — DB-backed, admin CRUD | ✅ 9/9 |
| 4 | Customer identity — real users, profile (dine-in/pickup only, no addresses) | ✅ 10/10 |
| 5 | Orders end-to-end — checkout, placement, admin actions | ✅ 12/12 |
| 6 | Loyalty end-to-end — real QR, stamps, redeem | ✅ 9/9 |
| 7 | Live updates via polling (no Firestore) | 🔲 0/3 |
| 8 | Flutter admin app | 🔲 0/13 |
| 9 | Push notifications (includes Firebase project setup, moved from old Phase 7) | 🔲 0/7 |
| 10 | Test, deploy, launch | 🔲 0/5 |

> Phases 0–2 are pure groundwork with nothing visible to show. Resist the urge to skip
> them; every later phase assumes they exist.

---

## Phase 0 — Repo hygiene (do this first, today)

Small, fast, and it makes everything after it safer.

- [ ] **P0-1 · S ·** Fix the build-breaking type error: `app/(standalone)/profile/page.tsx`
      line ~421 destructures `totalOrders` from `MOCK_LOYALTY`, which doesn't define it.
      Add `totalOrders` to `MOCK_LOYALTY` in `lib/mock-user-data.ts` (it's temporary
      anyway). **Verify `npm run build` passes** — until it does, nothing else is real.
- [ ] **P0-2 · S ·** 🔴 **Rotate `AUTH_GOOGLE_SECRET` and `AUTH_SECRET`.** Live
      credentials shipped inside the shared project zip. Regenerate the OAuth client
      secret in Google Cloud Console and generate a fresh `AUTH_SECRET`
      (`openssl rand -hex 32`). Update `.env.local`. Never zip `.env.local` again.
- [ ] **P0-3 · S ·** Delete the empty `app/admin/` and `app/kitchen/` folders. There is
      no web admin panel — leaving these invites an agent to build one.
- [ ] **P0-4 · S ·** Create `.env.example` with every key from `PROJECT_CONTEXT.md` §6,
      values blank. Commit it.
- [ ] **P0-5 · S ·** Untrack `tsconfig.tsbuildinfo`
      (`git rm --cached tsconfig.tsbuildinfo`) — `.gitignore` already covers
      `*.tsbuildinfo`, but it's currently committed.
- [ ] **P0-6 · S ·** Replace the default `create-next-app` `README.md` with a real one:
      what the project is, setup steps, env vars, links to the five docs.
- [ ] **P0-7 · S ·** Commit these five docs into a `docs/` folder. Point `CLAUDE.md` and
      `AGENTS.md` at `docs/PROJECT_CONTEXT.md` so any AI tool reads context first.

---

## Phase 1 — Database foundation

Nothing user-visible ships here. Everything after it depends on it.

- [x] **P1-1 · S ·** Create the MongoDB Atlas M0 cluster, a database user, and network
      access (allow-all is acceptable for Vercel's dynamic IPs). Put the URI in
      `MONGODB_URI`.
- [x] **P1-2 · M ·** Write `lib/db.ts`: a `connectDB()` helper caching the mongoose
      connection on `globalThis`. **This is not optional** — serverless cold starts will
      otherwise exhaust M0's connection cap. Make it idempotent.
- [x] **P1-3 · M ·** `model/MenuItem.ts` and `model/Category.ts`, matching
      `ARCHITECTURE.md` §3. Keep the field name **`image`**, not `imageUrl`, so no UI
      changes are needed. Images are bundled static files with no upload pipeline —
      see `ARCHITECTURE.md` §5.5.
      changes are needed. Index `categorySlug`.
- [x] **P1-4 · M ·** `model/Customer.ts` — including `addresses[]`, `preferences`,
      `stampToken`, `redeemToken`. Unique indexes on `googleId`, `email`, and both tokens.
- [x] **P1-5 · S ·** `model/LoyaltyCard.ts` — `stamps` default 0, `totalRequired`
      default 10, unique index on `customerId`.
- [x] **P1-6 · M ·** `model/Order.ts` — the 4-state status enum, snapshotted items and
      address, compound index on `{ status, placedAt: -1 }`.
- [x] **P1-7 · S ·** `model/Admin.ts` — `username`, `passwordHash`, `fcmTokens[]`.
- [x] **P1-8 · M ·** `scripts/seed.ts`: reads `CATEGORIES` and `MOCK_MENU` from
      `lib/menu-data.ts` and inserts them into Mongo. Make it idempotent (upsert by
      slug/name) so you can re-run it safely. Run it and confirm in Atlas.

---

## Phase 2 — Admin authentication

Small phase, but every admin endpoint in Phases 3–6 is blocked on it.

- [x] **P2-1 · S ·** `scripts/create-admin.ts`: prompts for a username and password,
      bcrypt-hashes it, inserts the **one** `Admin` document. Run once, then never again.
- [x] **P2-2 · M ·** `POST /api/admin/login` — bcrypt compare, sign a 24h JWT with
      `ADMIN_JWT_SECRET`, return `{ token }`. Generic error message on failure (never
      reveal whether the username exists).
- [x] **P2-3 · M ·** `lib/admin-auth.ts` exporting `requireAdmin(request)` — verifies the
      `Authorization: Bearer` header, returns the admin or throws a 401. **Every** admin
      route uses this; none rolls its own check.
- [x] **P2-4 · M ·** Rate-limit the login route (5 attempts / 15 min per IP). A simple
      in-memory map is acceptable at this scale; note in a comment that it resets per
      serverless instance.
- [x] **P2-5 · S ·** `lib/api-error.ts`: an `ApiError` class and a `handleApiError()`
      returning the standard `{ error: { code, message } }` envelope. Adopt it in every
      route from here on.

---

## Phase 3 — Menu, end to end

First phase with a visible payoff: the owner can change the menu from a phone.

- [x] **P3-1 ·** ✅ Menu data model and `CATEGORIES` / `MOCK_MENU` — in `lib/menu-data.ts`.
- [x] **P3-2 ·** ✅ `GET /api/menu` route with `?category=`, `?type=`, `?available=`
      filters and the `Cache-Control` header — built, but reading the mock array.
- [x] **P3-3 · M ·** Swap `GET /api/menu`'s data source to a Mongo query.
      **The response shape, query params, and cache header must stay byte-identical** —
      the Flutter app will be written against this contract.
- [x] **P3-4 · S ·** `GET /api/categories`, split out for reuse.
- [x] **P3-5 · M ·** `app/(customer)/page.tsx`: fetch from `/api/menu` with `useSWR`
      instead of importing `MOCK_MENU`. **Do not touch the JSX or the filtering UX** —
      only the data source. Add loading and error states.
- [x] **P3-6 · S ·** Grey out unavailable items and block adding them to the cart (PRD C-8).
- [x] **P3-7 · M ·** `POST /api/menu` and `PUT /api/menu/:id` (admin) with full input
      validation.
- [x] **P3-8 · S ·** `DELETE /api/menu/:id` (admin).
- [x] **P3-9 · S ·** `PATCH /api/menu/:id/availability` (admin) — the single most-used
      admin endpoint.

> 🔒 **Decision:** no image-upload endpoint exists in v1. Menu photos are static files
> in `public/images/`, and the `image` field is set directly in MongoDB by the developer
> when a new photo is needed. See `ARCHITECTURE.md` §5.5. The `cloudinary` npm package
> is an unused leftover dependency — safe to remove whenever convenient, not urgent.
>
> ✅ **Checkpoint:** after P3-9, test every menu endpoint with curl or Postman. You now
> have a complete, testable menu API before a single line of Flutter exists.

---

## Phase 4 — Customer identity

- [x] **P4-1 ·** ✅ Google sign-in with Auth.js v5 and the edge-safe `auth.config.ts` /
      `auth.ts` split.
- [x] **P4-2 ·** ✅ `session.user.id` exposed via the `jwt` / `session` callbacks and the
      `types/next-auth.d.ts` augmentation.
- [x] **P4-3 · L ·** In `auth.ts`'s `jwt` callback, upsert a `Customer` on first sign-in
      (keyed on `googleId`), generating `stampToken` and `redeemToken`
      (`crypto.randomUUID()` or nanoid), and create the customer's `LoyaltyCard` at the
      same time. Set `token.id` to the Mongo `_id`.
      ⚠️ **Keep all DB code in `auth.ts`, never `auth.config.ts`** — `proxy.ts` imports
      the latter into the edge runtime and mongoose will break the build there.
- [x] **P4-4 · S ·** `GET /api/me` — the current customer's profile.
- [x] **P4-5 · M ·** `PATCH /api/me` — update preference toggles.
      ⚠️ *Originally also handled `phone`; phone support was removed in P4-8 below —
      built history is fine as-is, this note just flags it's since changed.*
- [x] **P4-6 · M ·** 🔒 **REPURPOSED — decision changed mid-phase.** Originally address
      CRUD; now instead corrects `model/Customer.ts`, `model/Order.ts`, and
      `app/api/me/route.ts` to remove delivery/address support entirely (those two
      models were built in Phase 1, before this decision was made). No delivery
      fulfillment, no address book, ever — see `PROJECT_CONTEXT.md` §4.7.
- [x] **P4-7 · M ·** Profile page: replace `MOCK_LOYALTY` and `getRecentOrders()` with
      real fetches. Keep the same function signature, exactly as that file's own comments
      intend. **Then delete `lib/mock-user-data.ts`.**
- [x] **P4-8 · M ·** 🔒 **REPURPOSED — decision changed.** Originally a phone-collection
      flow; now instead REMOVES phone support entirely. Google sign-in's unique
      identity is sufficient — see `ARCHITECTURE.md` §5.7. Corrects: `model/Customer.ts`
      (remove `phone`), `model/Order.ts` (remove `customerPhone`),
      `app/api/me/route.ts` (remove `phone` from GET response and PATCH handling), and
      the profile page (remove the phone display/edit UI that P4-7 just wired in).
- [x] **P4-9 ·** 🔒 **REMOVED — decision: no delivery, no address book.** The static
      address label in the profile UI can stay as inert text or be removed; no backend
      work needed here at all.
- [x] **P4-10 · M ·** Make "delete account" actually delete the customer, their card, and
      (anonymize, don't delete) their orders — completing the TODO at
      `profile/page.tsx` ~line 809.

---

## Phase 5 — Orders, end to end

The biggest phase. Do it in this order or you'll rework the UI twice.

- [x] **P5-1 ·** ✅ Order tracking UI with status timeline and grouped sections.
- [x] **P5-2 ·** ✅ Cart with Zustand + localStorage persistence.
- [x] **P5-3 · M ·** **Simplify the status enum first**, before wiring anything:
      `pending | accepted | completed | rejected`. Remove `preparing` / `ready` / `served`
      from `orders/page.tsx`'s `STATUS_CONFIG`, `StatusTrack`, and the grouping logic.
      Doing this before P5-8 means you wire the UI up once, not twice.
- [x] **P5-4 · M ·** "Place Order" opens a simple popup: Dine-in or Pickup. Dine-in
      shows an OPTIONAL table-number field (never required); pickup shows an estimated
      ready time and nothing else (PRD C-12).
- [x] **P5-5 ·** 🔒 **REMOVED — decision: no delivery, no delivery fee.** The cart's
      "Delivery fee" line is deleted outright, not made conditional (PRD C-13).
- [x] **P5-6 · L ·** `POST /api/orders` (customer session). Must: validate fulfillment
      fields, reject unavailable or deleted items with a 409, and **recompute the total
      server-side from DB prices**, ignoring anything the client sent.
- [x] **P5-7 · S ·** `GET /api/orders/me` — the customer's own orders, newest first.
- [x] **P5-8 · M ·** Orders page: replace `INITIAL_ORDERS` and the local `useState` with
      a real `useSWR` fetch from `/api/orders/me`. Split active vs. history tabs.
- [x] **P5-9 · M ·** Wire "Place Order" to `POST /api/orders`; clear the cart on success
      and route to Orders. Block checkout with a clear message if an item became
      unavailable (PRD C-15).
- [x] **P5-10 · M ·** `GET /api/orders?status=` (admin), with pagination.
- [x] **P5-11 · L ·** `PATCH /api/orders/:id/accept|reject|complete` (admin), sharing one
      transition-guard helper. **Only `pending→accepted`, `pending→rejected`, and
      `accepted→completed` are legal**; everything else returns 409. Unit-test this —
      it's the single most bug-prone piece of logic in the system.
- [x] **P5-12 · S ·** `GET /api/health` for uptime monitoring.

> ✅ **Checkpoint:** a customer can place a real order end-to-end and you can move it
> through its states with curl. No real-time yet — a refresh shows the change.

---

## Phase 6 — Loyalty, end to end

- [x] **P6-1 ·** ✅ Stamp-card UI with fill animation and "Reward Ready" state.
- [x] **P6-2 · S ·** `GET /api/loyalty/me` — returns the card and `stampToken`, and
      `redeemToken` **only when `rewardReady` is true**. Never leak the redeem token early.
- [x] **P6-3 · M ·** Install `qrcode.react` and replace the decorative `QR_GRID` div
      matrix with a **real, scannable QR** encoding `stampToken`. Keep the existing
      visual framing — only the code itself becomes real.
- [x] **P6-4 · M ·** Render the large redeem QR (encoding `redeemToken`) in the redeem
      modal, and only mount it when the card is full.
- [x] **P6-5 · M ·** Wire the loyalty page to `/api/loyalty/me`, removing the hardcoded
      `LOYALTY` object.
- [x] **P6-6 · L ·** `GET /api/loyalty/scan/:token` (admin): resolve a token to a
      customer + card and return `action: "stamp" | "redeem"` based on **which field
      matched**. This is what lets the Flutter app refuse a mismatched mode.
- [x] **P6-7 · M ·** `POST /api/loyalty/:customerId/stamp` (admin): `stamps += 1`, set
      `rewardReady` when `stamps >= totalRequired`, never exceed the target.
- [x] **P6-8 · M ·** `POST /api/loyalty/:customerId/redeem` (admin): guard on
      `rewardReady`, reset to 0, and **rotate `redeemToken`** so the old QR dies.
- [x] **P6-9 · S ·** Unit-test the stamp/redeem/rotate logic (see
      `CODING_STANDARDS.md` §4).

> ✅ **Checkpoint:** the entire backend API from `ARCHITECTURE.md` §4 now exists except
> FCM push notifications (Phase 9). This is the right moment to start Flutter — but do
> Phase 7 first so you only integrate each endpoint once.

---

## Phase 7 — Live updates via polling (no Firestore)

🔒 **Decision: no Firestore.** The customer app gets order/loyalty updates via SWR
polling instead of a real-time database mirror — see `ARCHITECTURE.md` §5.8. Firebase
still appears later (Phase 9), but only for push notifications, not here.

- [ ] **P7-1 · M ·** Add polling to `app/(customer)/orders/page.tsx`: configure its
      `useSWR("/api/orders/me", ...)` call (already built in P5-8) with a
      `refreshInterval` of a few seconds (e.g. 5000ms) so status changes made by the
      admin app appear without a manual refresh, within that interval.
- [ ] **P7-2 · M ·** Add polling to `app/(customer)/loyalty/page.tsx`: same pattern on
      its `useSWR("/api/loyalty/me", ...)` call (P6-5) so a stamp appears within a few
      seconds of the admin scanning.
- [ ] **P7-3 · S ·** Pause polling when the browser tab isn't visible, on both pages —
      SWR supports this via its built-in focus/visibility handling
      (`revalidateOnFocus`, or pairing `refreshInterval` with the Page Visibility API)
      rather than polling a backgrounded tab pointlessly. Confirm polling resumes
      promptly when the tab regains focus.

> ✅ **Checkpoint:** change an order's status with curl, keep the customer's Orders
> page open, and watch it update within a few seconds with no manual refresh. Do the
> same for a loyalty stamp. The backend is now feature-complete for the web app.

---

## Phase 8 — Flutter admin app

Start here only once Phases 0–7 are done. Building Flutter against a half-finished API
means integrating everything twice.

- [ ] **P8-1 · M ·** Scaffold the Flutter project (Android only). Add the packages from
      `ARCHITECTURE.md` §7.
- [ ] **P8-2 · M ·** `theme/app_theme.dart` — brand brown `#3d1a00`, yellow `#facc15`,
      cream `#fff1e3`, Playfair headings via `google_fonts`, rounded shapes, tap-scale
      buttons. **Do this before any screen** so nothing hardcodes a color.
- [ ] **P8-3 · M ·** `core/api_client.dart`: dio + a JWT interceptor + central 401 → logout.
      `core/secure_store.dart` wrapping `flutter_secure_storage`.
- [ ] **P8-4 · M ·** Login screen → `POST /api/admin/login` → store the JWT. No other auth
      screens exist anywhere in the app.
- [ ] **P8-5 · M ·** `main_shell.dart` — bottom nav: **Menu / Loyalty / Orders**, in that
      order, plus auth-gated routing.
- [ ] **P8-6 · M ·** Models + services + Riverpod providers for menu, orders, and loyalty.
- [ ] **P8-7 · L ·** **Menu tab:** list with photo, name, price, and an availability
      switch calling `PATCH /api/menu/:id/availability` optimistically (revert on failure).
- [ ] **P8-8 · L ·** Menu add/edit form (shared widget): name, subtitle, price, category
      picker, veg/non-veg, featured. **No image field** — see `ARCHITECTURE.md` §5.5;
      photos are added by the developer directly in MongoDB, never through this app.
      Plus delete with confirmation.
- [ ] **P8-9 · L ·** **Loyalty tab:** an **Add Stamp / Redeem mode switch above** a
      `mobile_scanner` view. On scan → `/api/loyalty/scan/:token` → if the returned
      `action` doesn't match the selected mode, show an error and stop. **Never auto-switch
      modes.** Then show the card and require an explicit confirm tap.
- [ ] **P8-10 · L ·** **Orders tab:** segmented control (Pending/Accepted/Completed/
      Rejected), order cards showing fulfillment type + table number (dine-in only),
      items, customer,
      total, and relative time. Accept/Reject on pending, Complete on accepted; Reject
      needs confirmation.
- [ ] **P8-11 · M ·** Pull-to-refresh and a refresh-on-tab-focus poll as a safety net for
      when push fails.
- [ ] **P8-12 · M ·** A pending-count badge on the Orders tab icon.
- [ ] **P8-13 · M ·** Empty, loading, error, and offline states on all three tabs.
      `AsyncValue.when` makes this cheap — don't skip it.

---

## Phase 9 — Push notifications

Last major feature because it's the hardest to debug and depends on everything above.

- [ ] **P9-0 · M ·** Create the Firebase project (deferred from the old Phase 7, since
      Firestore was cut — see `ARCHITECTURE.md` §5.8). Enable **Cloud Messaging only**;
      Firestore does not need to be enabled at all. Generate a service account key and
      set the three `FIREBASE_*` env vars (see `PROJECT_CONTEXT.md` §6).
- [ ] **P9-1 · M ·** `POST /api/admin/fcm-token` — register/update a device token on the
      `Admin` document.
- [ ] **P9-2 · M ·** Flutter: request notification permission, get the FCM token, register
      it on login, and refresh it on token rotation.
- [ ] **P9-3 · L ·** Backend: on new order creation (P5-6), send an FCM message to every
      registered admin token. Prune tokens the FCM response reports as invalid.
- [ ] **P9-4 · L ·** Android custom notification channel with a raw sound asset, at high
      importance. ⚠️ A plain FCM notification will **not** reliably make noise with the
      app killed — the channel is mandatory, and it must be created before the first
      notification arrives.
- [ ] **P9-5 · M ·** Handle all three states — foreground, background, terminated — and
      deep-link a notification tap into the Orders tab, Pending filter.
- [ ] **P9-6 · M ·** Test on a **real device** with the app killed, screen off, and under
      battery optimization. Emulators are unreliable here. Document any OEM battery
      settings the owner needs to disable.

---

## Phase 10 — Test, deploy, launch

- [ ] **P10-1 · L ·** Write the backend unit tests listed in `CODING_STANDARDS.md` §4 —
      status transitions, total recomputation, stamp/redeem, and admin route protection.
- [ ] **P10-2 · M ·** Flutter widget tests: login, availability toggle, order actions.
- [ ] **P10-3 · M ·** Deploy to Vercel with every env var set. Run the seed script and
      the create-admin script against production. Point UptimeRobot at `/api/health`.
- [ ] **P10-4 · L ·** Run the full 8-step acceptance script from `PRD.md` §6 end-to-end on
      real devices. Fix everything it surfaces before shipping.
- [ ] **P10-5 · M ·** Generate the release keystore, build the signed APK, sideload it,
      and write a one-page handover note for the shop owner (how to log in, what to do
      if notifications stop).

---

## Dependency map — what blocks what

```
P0 (hygiene)
  └─► P1 (db + models)
        ├─► P2 (admin auth) ──┬─► P3 admin endpoints (P3-7…P3-9)
        │                     ├─► P5 admin endpoints (P5-10, P5-11)
        │                     └─► P6 admin endpoints (P6-6…P6-8)
        ├─► P3 (menu, DB-backed)
        ├─► P4 (customer identity) ──► P5 (orders) ──► P6 (loyalty)
        │        └─ P4-3 creates the LoyaltyCard that P6 depends on
        └─► P7 (polling) ── needs P5-8 + P6-5 (the SWR calls it configures)
              └─► P8 (flutter) ──► P9 (push + Firebase project) ──► P10 (launch)
```

**The three hard gates:**
1. **P0-1** — the build is red right now. Nothing counts until it's green.
2. **P2** — every admin endpoint is blocked on it. It's only ~half a day.
3. **P5-3** (status simplification) — do it *before* P5-8, or you'll wire the orders UI
   twice.

---

## Suggested pacing

| Week | Phases | You'll be able to... |
|---|---|---|
| 1 | 0, 1, 2 | ...see real data in Atlas and log in as admin via curl |
| 2 | 3 | ...manage the menu over HTTP; the web app reads the real DB |
| 3 | 4 | ...have real customer accounts identified purely by Google sign-in |
| 4–5 | 5 | ...place and fulfil a real order end-to-end |
| 6 | 6, 7 | ...watch stamps and statuses update within a few seconds, no manual refresh |
| 7–8 | 8 | ...run the shop from an Android phone |
| 9 | 9, 10 | ...get woken up by an order alert, and ship the APK |
