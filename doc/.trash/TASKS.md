# TASKS.md — Slice and Serve Build Roadmap

**How to use this:** work top to bottom. Every task is ordered so that its dependencies
are already done. Tick a box, commit, move on. Never skip ahead — the ordering is the
whole point.

- `[x]` done · `[~]` partially done · `[ ]` not started
- **Size:** S = under an hour · M = a few hours · L = a day or more
- Do **one task per commit**, referencing the ID (see `CODING_STANDARDS.md` §3).

**Progress:** 11 / 92 tasks complete (12%) — all of it front-end UI.

---

## Status at a glance

| Phase | What it delivers | Status |
|---|---|---|
| 0 | Repo hygiene — make the build green and safe | 🔲 0/7 |
| 1 | Database foundation — connection, models, seed | 🔲 0/8 |
| 2 | Admin auth — unblocks every admin endpoint | 🔲 0/5 |
| 3 | Menu end-to-end — DB-backed, admin CRUD, uploads | 🟡 2/10 |
| 4 | Customer identity — real users, addresses, profile | 🟡 2/10 |
| 5 | Orders end-to-end — checkout, placement, admin actions | 🟡 2/12 |
| 6 | Loyalty end-to-end — real QR, stamps, redeem | 🟡 1/9 |
| 7 | Real-time — Firestore mirror + live listeners | 🔲 0/7 |
| 8 | Flutter admin app | 🔲 0/13 |
| 9 | Push notifications | 🔲 0/6 |
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

- [ ] **P1-1 · S ·** Create the MongoDB Atlas M0 cluster, a database user, and network
      access (allow-all is acceptable for Vercel's dynamic IPs). Put the URI in
      `MONGODB_URI`.
- [ ] **P1-2 · M ·** Write `lib/db.ts`: a `connectDB()` helper caching the mongoose
      connection on `globalThis`. **This is not optional** — serverless cold starts will
      otherwise exhaust M0's connection cap. Make it idempotent.
- [ ] **P1-3 · M ·** `model/MenuItem.ts` and `model/Category.ts`, matching
      `ARCHITECTURE.md` §3. Keep the field name **`image`**, not `imageUrl`, so no UI
      changes are needed. Index `categorySlug`.
- [ ] **P1-4 · M ·** `model/Customer.ts` — including `addresses[]`, `preferences`,
      `stampToken`, `redeemToken`. Unique indexes on `googleId`, `email`, and both tokens.
- [ ] **P1-5 · S ·** `model/LoyaltyCard.ts` — `stamps` default 0, `totalRequired`
      default 10, unique index on `customerId`.
- [ ] **P1-6 · M ·** `model/Order.ts` — the 4-state status enum, snapshotted items and
      address, compound index on `{ status, placedAt: -1 }`.
- [ ] **P1-7 · S ·** `model/Admin.ts` — `username`, `passwordHash`, `fcmTokens[]`.
- [ ] **P1-8 · M ·** `scripts/seed.ts`: reads `CATEGORIES` and `MOCK_MENU` from
      `lib/menu-data.ts` and inserts them into Mongo. Make it idempotent (upsert by
      slug/name) so you can re-run it safely. Run it and confirm in Atlas.

---

## Phase 2 — Admin authentication

Small phase, but every admin endpoint in Phases 3–6 is blocked on it.

- [ ] **P2-1 · S ·** `scripts/create-admin.ts`: prompts for a username and password,
      bcrypt-hashes it, inserts the **one** `Admin` document. Run once, then never again.
- [ ] **P2-2 · M ·** `POST /api/admin/login` — bcrypt compare, sign a 24h JWT with
      `ADMIN_JWT_SECRET`, return `{ token }`. Generic error message on failure (never
      reveal whether the username exists).
- [ ] **P2-3 · M ·** `lib/admin-auth.ts` exporting `requireAdmin(request)` — verifies the
      `Authorization: Bearer` header, returns the admin or throws a 401. **Every** admin
      route uses this; none rolls its own check.
- [ ] **P2-4 · M ·** Rate-limit the login route (5 attempts / 15 min per IP). A simple
      in-memory map is acceptable at this scale; note in a comment that it resets per
      serverless instance.
- [ ] **P2-5 · S ·** `lib/api-error.ts`: an `ApiError` class and a `handleApiError()`
      returning the standard `{ error: { code, message } }` envelope. Adopt it in every
      route from here on.

---

## Phase 3 — Menu, end to end

First phase with a visible payoff: the owner can change the menu from a phone.

- [x] **P3-1 ·** ✅ Menu data model and `CATEGORIES` / `MOCK_MENU` — in `lib/menu-data.ts`.
- [x] **P3-2 ·** ✅ `GET /api/menu` route with `?category=`, `?type=`, `?available=`
      filters and the `Cache-Control` header — built, but reading the mock array.
- [ ] **P3-3 · M ·** Swap `GET /api/menu`'s data source to a Mongo query.
      **The response shape, query params, and cache header must stay byte-identical** —
      the Flutter app will be written against this contract.
- [ ] **P3-4 · S ·** `GET /api/categories`, split out for reuse.
- [ ] **P3-5 · M ·** `app/(customer)/page.tsx`: fetch from `/api/menu` with `useSWR`
      instead of importing `MOCK_MENU`. **Do not touch the JSX or the filtering UX** —
      only the data source. Add loading and error states.
- [ ] **P3-6 · S ·** Grey out unavailable items and block adding them to the cart (PRD C-8).
- [ ] **P3-7 · M ·** `POST /api/menu` and `PUT /api/menu/:id` (admin) with full input
      validation.
- [ ] **P3-8 · S ·** `DELETE /api/menu/:id` (admin).
- [ ] **P3-9 · S ·** `PATCH /api/menu/:id/availability` (admin) — the single most-used
      admin endpoint.
- [ ] **P3-10 · M ·** `POST /api/upload/signature` (admin): returns Cloudinary signed
      upload params so the Flutter app uploads directly without ever holding the API
      secret. (`cloudinary` is already a dependency, currently unused.)

> ✅ **Checkpoint:** after P3-10, test every menu endpoint with curl or Postman. You now
> have a complete, testable menu API before a single line of Flutter exists.

---

## Phase 4 — Customer identity

- [x] **P4-1 ·** ✅ Google sign-in with Auth.js v5 and the edge-safe `auth.config.ts` /
      `auth.ts` split.
- [x] **P4-2 ·** ✅ `session.user.id` exposed via the `jwt` / `session` callbacks and the
      `types/next-auth.d.ts` augmentation.
- [ ] **P4-3 · L ·** In `auth.ts`'s `jwt` callback, upsert a `Customer` on first sign-in
      (keyed on `googleId`), generating `stampToken` and `redeemToken`
      (`crypto.randomUUID()` or nanoid), and create the customer's `LoyaltyCard` at the
      same time. Set `token.id` to the Mongo `_id`.
      ⚠️ **Keep all DB code in `auth.ts`, never `auth.config.ts`** — `proxy.ts` imports
      the latter into the edge runtime and mongoose will break the build there.
- [ ] **P4-4 · S ·** `GET /api/me` — the current customer's profile.
- [ ] **P4-5 · M ·** `PATCH /api/me` — update phone and preference toggles.
- [ ] **P4-6 · M ·** Address CRUD: `GET`/`POST /api/me/addresses`,
      `PUT`/`DELETE /api/me/addresses/:id`, including default-address handling.
- [ ] **P4-7 · M ·** Profile page: replace `MOCK_LOYALTY` and `getRecentOrders()` with
      real fetches. Keep the same function signature, exactly as that file's own comments
      intend. **Then delete `lib/mock-user-data.ts`.**
- [ ] **P4-8 · M ·** Build a phone-number collection flow (PRD C-31). Required before a
      first order, since orders snapshot `customerPhone`.
- [ ] **P4-9 · M ·** Turn the static address label into a real saved-address UI backed by
      P4-6.
- [ ] **P4-10 · M ·** Make "delete account" actually delete the customer, their card, and
      (anonymize, don't delete) their orders — completing the TODO at
      `profile/page.tsx` ~line 809.

---

## Phase 5 — Orders, end to end

The biggest phase. Do it in this order or you'll rework the UI twice.

- [x] **P5-1 ·** ✅ Order tracking UI with status timeline and grouped sections.
- [x] **P5-2 ·** ✅ Cart with Zustand + localStorage persistence.
- [ ] **P5-3 · M ·** **Simplify the status enum first**, before wiring anything:
      `pending | accepted | completed | rejected`. Remove `preparing` / `ready` / `served`
      from `orders/page.tsx`'s `STATUS_CONFIG`, `StatusTrack`, and the grouping logic.
      Doing this before P5-8 means you wire the UI up once, not twice.
- [ ] **P5-4 · L ·** Checkout fulfillment step: dine-in / pickup / delivery selector,
      with a table-number input for dine-in and a saved-address picker for delivery
      (PRD C-12).
- [ ] **P5-5 · S ·** Apply the delivery fee **only** to delivery orders — the cart
      currently shows it unconditionally (PRD C-13).
- [ ] **P5-6 · L ·** `POST /api/orders` (customer session). Must: validate fulfillment
      fields, reject unavailable or deleted items with a 409, and **recompute the total
      server-side from DB prices**, ignoring anything the client sent.
- [ ] **P5-7 · S ·** `GET /api/orders/me` — the customer's own orders, newest first.
- [ ] **P5-8 · M ·** Orders page: replace `INITIAL_ORDERS` and the local `useState` with
      a real `useSWR` fetch from `/api/orders/me`. Split active vs. history tabs.
- [ ] **P5-9 · M ·** Wire "Place Order" to `POST /api/orders`; clear the cart on success
      and route to Orders. Block checkout with a clear message if an item became
      unavailable (PRD C-15).
- [ ] **P5-10 · M ·** `GET /api/orders?status=` (admin), with pagination.
- [ ] **P5-11 · L ·** `PATCH /api/orders/:id/accept|reject|complete` (admin), sharing one
      transition-guard helper. **Only `pending→accepted`, `pending→rejected`, and
      `accepted→completed` are legal**; everything else returns 409. Unit-test this —
      it's the single most bug-prone piece of logic in the system.
- [ ] **P5-12 · S ·** `GET /api/health` for uptime monitoring.

> ✅ **Checkpoint:** a customer can place a real order end-to-end and you can move it
> through its states with curl. No real-time yet — a refresh shows the change.

---

## Phase 6 — Loyalty, end to end

- [x] **P6-1 ·** ✅ Stamp-card UI with fill animation and "Reward Ready" state.
- [ ] **P6-2 · S ·** `GET /api/loyalty/me` — returns the card and `stampToken`, and
      `redeemToken` **only when `rewardReady` is true**. Never leak the redeem token early.
- [ ] **P6-3 · M ·** Install `qrcode.react` and replace the decorative `QR_GRID` div
      matrix with a **real, scannable QR** encoding `stampToken`. Keep the existing
      visual framing — only the code itself becomes real.
- [ ] **P6-4 · M ·** Render the large redeem QR (encoding `redeemToken`) in the redeem
      modal, and only mount it when the card is full.
- [ ] **P6-5 · M ·** Wire the loyalty page to `/api/loyalty/me`, removing the hardcoded
      `LOYALTY` object.
- [ ] **P6-6 · L ·** `GET /api/loyalty/scan/:token` (admin): resolve a token to a
      customer + card and return `action: "stamp" | "redeem"` based on **which field
      matched**. This is what lets the Flutter app refuse a mismatched mode.
- [ ] **P6-7 · M ·** `POST /api/loyalty/:customerId/stamp` (admin): `stamps += 1`, set
      `rewardReady` when `stamps >= totalRequired`, never exceed the target.
- [ ] **P6-8 · M ·** `POST /api/loyalty/:customerId/redeem` (admin): guard on
      `rewardReady`, reset to 0, and **rotate `redeemToken`** so the old QR dies.
- [ ] **P6-9 · S ·** Unit-test the stamp/redeem/rotate logic (see
      `CODING_STANDARDS.md` §4).

> ✅ **Checkpoint:** the entire backend API from `ARCHITECTURE.md` §4 now exists except
> the Firestore mirror and FCM. This is the right moment to start Flutter — but do
> Phase 7 first so you only integrate each endpoint once.

---

## Phase 7 — Real-time layer

- [ ] **P7-1 · M ·** Create the Firebase project; enable Firestore and Cloud Messaging;
      generate a service account key; set the three `FIREBASE_*` env vars.
- [ ] **P7-2 · M ·** `lib/firebase-admin.ts` — initialize the Admin SDK once, cached on
      `globalThis` for serverless reuse.
- [ ] **P7-3 · M ·** Mirror-write helpers: after every successful Mongo write in P5-11
      (order status) and P6-7/P6-8 (stamps), write to `orders/{id}` and
      `loyaltyCards/{customerId}`. **Always after the Mongo write, never before.** A
      failed mirror write is logged, not fatal.
- [ ] **P7-4 · M ·** `lib/firebase-client.ts` — the web SDK with the three
      `NEXT_PUBLIC_FIREBASE_*` vars, read-only.
- [ ] **P7-5 · L ·** Subscribe the orders page to Firestore for the orders currently on
      screen. **Unsubscribe in the `useEffect` cleanup.** Never listen to the whole
      collection — free-tier read quota is real.
- [ ] **P7-6 · M ·** Subscribe the loyalty page to `loyaltyCards/{customerId}` so a stamp
      animates in live.
- [ ] **P7-7 · M ·** Publish the Firestore security rules: a customer reads only their own
      two docs; **all client writes denied**. Test that a client write is actually rejected.

> ✅ **Checkpoint:** change an order's status with curl and watch the customer's browser
> update with no refresh. The backend is now feature-complete.

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
      picker, veg/non-veg, featured, image picker → Cloudinary signed upload → save URL.
      Plus delete with confirmation.
- [ ] **P8-9 · L ·** **Loyalty tab:** an **Add Stamp / Redeem mode switch above** a
      `mobile_scanner` view. On scan → `/api/loyalty/scan/:token` → if the returned
      `action` doesn't match the selected mode, show an error and stop. **Never auto-switch
      modes.** Then show the card and require an explicit confirm tap.
- [ ] **P8-10 · L ·** **Orders tab:** segmented control (Pending/Accepted/Completed/
      Rejected), order cards showing fulfillment type + table/address, items, customer,
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
        ├─► P2 (admin auth) ──┬─► P3 admin endpoints (P3-7…P3-10)
        │                     ├─► P5 admin endpoints (P5-10, P5-11)
        │                     └─► P6 admin endpoints (P6-6…P6-8)
        ├─► P3 (menu, DB-backed)
        ├─► P4 (customer identity) ──► P5 (orders) ──► P6 (loyalty)
        │        └─ P4-3 creates the LoyaltyCard that P6 depends on
        └─► P7 (firestore mirror) ── needs P5-11 + P6-7/8 to exist first
              └─► P8 (flutter) ──► P9 (push) ──► P10 (launch)
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
| 3 | 4 | ...have real customer accounts with addresses and phones |
| 4–5 | 5 | ...place and fulfil a real order end-to-end |
| 6 | 6, 7 | ...watch stamps and statuses update live, no refresh |
| 7–8 | 8 | ...run the shop from an Android phone |
| 9 | 9, 10 | ...get woken up by an order alert, and ship the APK |
