# PRD.md — Slice and Serve Admin (Flutter)

Product requirements for the **Android admin app only**.  
Every requirement is tagged with its build stage — **[A]** Stage A (built on mock data,
no API calls) or **[B]** Stage B (wired to the real backend) — per the split defined in
`PROJECT_CONTEXT.md` §2. Where a requirement has both a visual/behavioral part and a
real-data part, it's split into an `[A]` line and a `[B]` line so Stage A's scope is
unambiguous. All still 🔲 not started at the time this document was written.

The customer web app is out of scope. This document describes only what the shop owner experiences on their phone.

---

## 1. Vision

A single Android app that lets the shop owner (one person) run the entire daily operation of a small fast-food shop:

- Toggle menu items available / unavailable in seconds
- Scan customer loyalty QRs to add stamps or redeem rewards
- See and act on incoming orders (Accept / Reject / Complete)
- Get woken up by a new-order notification even when the app is killed

No cashier terminal, no web admin, no multi-user support, no payment gateway.  
Everything runs on free tiers. Distribution is a signed APK sideloaded onto the owner’s phone.

**Success for v1** = the owner can process real daily orders and loyalty stamps entirely from this app, with reliable push notifications and zero need to touch the customer web app or a notebook.

---

## 2. Users

| User              | Count | Device          | Auth                          |
|-------------------|-------|-----------------|-------------------------------|
| Shop owner / staff| 1     | One Android phone | Fixed username + password → JWT |

There is deliberately **no** multi-staff support, no roles, no self-service account management, no forgot-password, and no change-password flow.

---

## 3. Core requirements

### 3.1 Authentication

- **A-1** [A] 🔲 Single login screen: username + password fields, brand-styled primary
  CTA, loading state on submit, inline error state. On mock data: any non-empty input
  "succeeds" and navigates forward; a sentinel value (e.g. password `"fail"`) triggers
  the error state so it's reviewable.
  [B] 🔲 Submit calls `POST /api/admin/login` → stores the returned JWT in
  `flutter_secure_storage`. Never store the JWT in SharedPreferences or plain storage.
- **A-2** [A] 🔲 No signup, no forgot-password, no change-password, no account/settings
  screen anywhere in the app — not even a placeholder for one. Corresponding backend
  endpoints do not exist and must not be invented.
- **A-3** [B] 🔲 Any `401` response from the API clears the stored token and navigates
  to the login screen. Handled centrally in the dio interceptor, never per-screen.
- **A-4** [B] 🔲 Session survives app restart until the JWT expires (24 h). On cold
  start, if a valid token exists, go straight to the main shell.

### 3.2 Main shell & navigation

- **A-5** [A] 🔲 Bottom navigation with exactly four tabs, in this order:
  **Menu · Loyalty · Orders · Settings**, brand-styled active/inactive states.
  🔒 *Amended after the Stage A review — originally three tabs; Settings added as §3.8.*
- **A-6** [A] 🔲 Auth-gated on mock login state: unauthenticated users only ever see
  the login screen. [B] 🔲 Gated for real once Stage B's auth is wired.
- **A-7** [A] 🔲 Orders tab shows a badge with a pending count — hardcoded on mock data
  for Stage A so its visual treatment is reviewable. [B] 🔲 Reflects the real pending
  count, refreshed at minimum on each visit to the tab.
- **A-8** [A] 🔲 Pull-to-refresh gesture wired visually on every tab (spinner/indicator),
  even before a real fetch exists behind it. [B] 🔲 A refresh-on-tab-focus poll as a
  safety net when push fails.
- **A-8b** [A] 🔲 🔒 *Added after the Stage A review.* A branded native splash screen
  (background from `DESIGN_TOKENS.md`'s brand background token + logo/wordmark),
  shown on cold start before the first frame renders. Configured for both light and
  dark system settings, not a single fixed appearance.

### 3.3 Menu tab

- **A-9** [A] 🔲 List all menu items with: photo placeholder (per A-16 — no real images
  exist yet on mock data either, so this is the permanent placeholder treatment, not a
  temporary one), name, price, availability switch. Mock list covers both available and
  unavailable items so both switch states are reviewable.
- **A-10** [A] 🔲 The availability switch toggles local mock state so its on/off visual
  states are reviewable. [B] 🔲 Toggling calls `PATCH /api/menu/:id/availability`
  **optimistically** — flip immediately, revert and show a clear error if the request
  fails.
- **A-11** [A] 🔲 Floating "+" button opens a create form.
- **A-12** [A] 🔲 Tapping an item opens the same form pre-filled for editing.
- **A-13** [A] 🔲 Form fields (create + edit): name, subtitle, price, category picker
  (against a small hardcoded mock category list for Stage A), veg / non-veg, featured.
  **No image field of any kind.** [B] 🔲 Category picker's options come from
  `GET /api/categories` instead of the mock list; form submits to `POST`/`PUT /api/menu`
  with real validation errors surfaced inline.
- **A-14** [A] 🔲 Delete requires an explicit confirmation dialog (mock — doesn't
  persist yet). [B] 🔲 Confirmed delete calls `DELETE /api/menu/:id`.
- **A-15** [A] 🔲 Empty, loading, and error states are designed and friendly on this
  tab, each reachable via a mock trigger for review.

**Decision reminder (A-16):**  
There is **never** an image upload, image picker, or photo management UI.  
A newly created item shows a placeholder until the developer manually places a file in `public/images/` and sets the `image` path in MongoDB. This is intentional and permanent for v1.

### 3.4 Loyalty tab

- **A-17** [A] 🔲 Mode switch at the top of the screen: **Add Stamp** | **Redeem**. A
  placeholder camera-preview-shaped view sits below it (real `mobile_scanner` is
  Stage B).
- **A-18** [A] 🔲 A "simulate scan" mock trigger drives the result card for review
  purposes. [B] 🔲 A real scan calls `GET /api/loyalty/scan/:token`; the response
  tells the app which action the token is valid for (`"stamp"` or `"redeem"`).
- **A-19** [A] 🔲 A clear, brand-styled error state exists for "this doesn't match the
  selected mode," reachable via a mock trigger. [B] 🔲 If the real `action` doesn't
  match the currently selected mode → show that error and **do nothing**. Never
  auto-switch modes, never fall back to the other action.
- **A-20** [A] 🔲 Design the result card for BOTH modes — a stamp-confirmation and a
  redeem-confirmation card, visually distinct since redeem is a bigger, more
  deliberate action. Each shows customer name + card progress (e.g. 6/10) + an
  explicit Confirm button. [B] 🔲 Populated with real scan data; never act on the scan
  alone, only on Confirm.
- **A-21** [B] 🔲 Redeem is only ever offered when the real scan result's card shows
  `rewardReady === true`. The backend also enforces this; the UI still guards it.
- **A-22** [A] 🔲 Success feedback state designed (visible confirmation), plus haptic
  wired in (`HapticFeedback` — not a visual review item, but wire it alongside the
  visual state). [B] 🔲 After a real confirmed action, return to the scanner ready for
  the next customer.
- **A-23** [A] 🔲 Empty / loading / error / camera-permission states designed and
  reachable via mock triggers. [B] 🔲 Driven by real camera-permission and network
  states.

### 3.5 Orders tab

> 🔒 **Amended after the Stage A review** — the segment structure and status display
> below reflect the revision (task `4A-5`), not the original build. The underlying
> order status stored via the API is unchanged — still `pending` / `accepted` /
> `completed` / `rejected`, per the fixed backend enum in `PROJECT_CONTEXT.md` §4.
> Only what's *displayed* changed.

- **A-24** [A] 🔲 Segmented control (or equivalent): **Pending · Preparing ·
  Completed** — three segments, not four. **"Preparing" is a display-only label for
  the `accepted` status** — the order's actual status value is still `accepted`
  everywhere in code and in the API; only the label shown to the user changed. Mock
  list, newest first within each segment.
- **A-25** [A] 🔲 Each order card shows, on mock data covering every combination:
  - Fulfillment type (`dine-in` or `pickup`)
  - Table number (only when fulfillment is `dine-in` — mock data must include a
    dine-in order with NO table number, since that's explicitly optional and its
    absence needs to look intentional, not broken)
  - Item list with quantities
  - Customer name
  - Total
  - Relative timestamp ("2 min ago", etc.)
- **A-26** [A] 🔲 Action buttons, correct per status on mock data:
  - Pending → **Accept** and **Reject** (button labels stay the verbs "Accept"/
    "Reject" — only the segment header display changes, not the action button text)
  - Preparing (i.e. `accepted`) → **Complete**
  - Completed → read-only (no actions, not even disabled ones)
- **A-27** [A] 🔲 Reject requires a second confirmation (it is irreversible) — same
  confirmation pattern as menu-item delete (A-14). **The Reject action itself is
  unchanged and still exists** — what changed is there's no longer a segment to browse
  rejected orders afterward. Once rejected, an order simply leaves the visible list
  entirely (filtered out of all three remaining segments). This is a deliberate
  decision, not an oversight: rejected orders aren't something the owner needs to
  revisit.
- **A-28** [A]/[B] 🔲 Pending-count badge on the Orders tab icon (see A-7 — same
  mock-then-real split). Counts only orders in the `pending` status — a rejected or
  completed order was never counted here regardless of this revision.
- **A-29** [A] 🔲 Empty, loading, and error states are first-class on this tab, mock
  triggers reachable for review.
  [B] 🔲 List loads from `GET /api/orders?status=`, refetched on pull-to-refresh and
  tab navigation. Accept/Reject/Complete call their respective
  `PATCH /api/orders/:id/...` endpoints; a 409 (stale list) shows a clear error and
  refreshes the list rather than leaving a dead action button. Note: the app can still
  fetch `?status=rejected` from the API if ever needed later (the backend doesn't
  restrict this) — the three-segment limit is purely a UI decision, not an API one.

### 3.6 Push notifications — after Stage B, not part of Stage A or B

- **A-30** [Push] 🔲 On login (and on token refresh), register the FCM device token
  with `POST /api/admin/fcm-token`.
- **A-31** [Push] 🔲 When a new order is created, the backend sends an FCM message to
  every registered admin token (backend-side work, tracked in the Next.js repo's own
  `TASKS.md`, not here).
- **A-32** [Push] 🔲 Android notification channel:
  - Custom high-importance channel
  - Raw sound asset (not the default system sound)
  - Channel must be created **before** the first notification arrives
- **A-33** [Push] 🔲 Handle all three app states correctly: foreground, background,
  terminated (app killed).
- **A-34** [Push] 🔲 Tapping a notification deep-links into the Orders tab with the
  Pending filter selected.
- **A-35** [Push] 🔲 Must be tested on a **real device** with the app killed, screen
  off, and under typical battery-optimization settings. Emulators are unreliable for
  this.

### 3.7 Resilience & polish

- **A-36** [A]/[B] 🔲 Every async screen uses `AsyncValue.when` (or equivalent) and
  explicitly handles loading / data / error / empty — designed with mock triggers in
  Stage A, driven by real state in Stage B.
- **A-37** [B] 🔲 Offline or network-error states show a clear message and a retry
  action (needs a real network to actually fail against).
- **A-38** [A] 🔲 All interactive elements give immediate press feedback (scale +
  optional light haptic) — this is a Stage A visual/interaction requirement, true from
  the first screen built.
- **A-39** [A] 🔲 Primary actions live in the thumb zone.
- **A-40** [A] 🔲 The entire app must feel calm, premium, and trustworthy on first
  launch (see polished-flutter-ui skill) — this is Stage A's actual exit criterion,
  not a Stage B afterthought.

---

### 3.8 Settings tab — added after the Stage A review

> 🔒 New scope, not in the original build. All of this is Stage A / local-only —
> the theme preference persists via on-device storage (`shared_preferences`), not a
> backend call, so it's built for real now rather than mocked.

- **A-41** [A] 🔲 Fourth bottom-nav tab, **Settings**, positioned after Orders.
  Sections: Theme, About, Report a Bug.
- **A-42** [A] 🔲 Theme picker: **Light** (default) / Dark / System — a clear
  radio-style selection. Choosing an option immediately updates the app's theme AND
  persists the choice on-device, read back on next launch so it survives a restart.
- **A-43** [A] 🔲 App version displayed (from the installed build, not hardcoded text).
- **A-44** [A] 🔲 "Check for update": **a static placeholder for v1** — no real
  update-check mechanism exists (there's no Play Store; this app is sideloaded).
  Tapping it can show something like "You're on the latest version" — it does not need
  to actually check anything against a server.
- **A-45** [A] 🔲 About section: static text describing the app/shop.
- **A-46** [A] 🔲 "Report a bug": tapping it shows a **static message with contact
  info** — no email intent, no in-app form, no backend submission. Simplest possible
  version for v1.

## 4. Explicitly out of scope for v1

- Multi-staff logins, roles, or permissions
- Signup / forgot-password / change-password / account screen
- Image upload, image picker, or any photo management
- Delivery fulfillment, addresses, delivery fees, phone numbers
- Analytics or sales dashboard
- Kitchen printer integration
- Customer-facing push notifications
- Play Store release / in-app updates
- Web admin panel
- Local business-data database or offline-first sync of orders/menu
- Any new backend endpoint not already defined in the shared API contract

---

## 5. Acceptance criteria (the only ones that matter)

This is the **final, post-Push-stage** exit criteria — the whole reason the app exists.
It assumes Stage A was already separately approved on its own terms (§3's `[A]` items,
reviewed on mock data, before any of this could even be attempted for real). The
following end-to-end flow must work on a real Android device before the APK is handed
to the owner:

1. Owner logs in with the single admin account.
2. Owner adds a new menu item (no photo) → it appears on the customer web menu after the next fetch.
3. Owner toggles an item unavailable → it greys out for customers.
4. Customer places a real order (dine-in or pickup).
5. Owner’s phone plays the **custom notification sound** while the app is **killed**; the order appears under Pending with correct fulfillment type, table number (if any), items, and total.
6. Owner taps Accept → order moves to Accepted.
7. Owner taps Complete → order moves to Completed.
8. Customer shows stamp QR → owner scans in **Add Stamp** mode → card increments (e.g. 6/10 → 7/10).
9. When the card reaches 10/10, customer shows redeem QR → owner scans in **Redeem** mode → card resets to 0/10 and the old redeem QR becomes invalid.
10. Scanning a stamp QR while in Redeem mode (or vice-versa) shows an error and does nothing.

If any of the above fails, the build is not ready.

---

**End of PRD.md**
