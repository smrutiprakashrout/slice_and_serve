# PRD.md — Slice and Serve

Product requirements for the customer web app and the Flutter admin app.
Every requirement is tagged: **✅ built** · **🟡 UI built, backend missing** · **🔲 not started**

---

## 1. Vision

A single fast-food shop runs its whole operation on two apps sharing one backend:
customers browse, order, track, and collect loyalty stamps on a web app; the owner
manages the menu, scans loyalty QRs, and works incoming orders on an Android app.
No cashier terminal, no payment gateway, no subscription costs — everything runs on
free tiers. The shop's own ordering system fulfills **dine-in and pickup only**;
customers who want delivery use Zomato separately, entirely outside this app.

**Success for v1 means:** the owner can place the shop's real daily orders through this
system instead of a notebook, and a customer can see their order go from Pending to
Completed without manually refreshing (a short polling delay of a few seconds is fine).

---

## 2. Users

| User | Count | Device | Auth |
|---|---|---|---|
| Customer | many | Mobile browser | Google sign-in |
| Shop owner / staff | 1 account | One Android phone | Fixed username + password |

There is deliberately **no** multi-staff support, no roles, no admin self-service.

---

## 3. Customer web app requirements

### 3.1 Sign in — ✅ built
- **C-1** ✅ Customer signs in with Google. Session persists as a JWT (no DB adapter).
- **C-2** ✅ Unauthenticated `/profile` shows a designed signed-out empty state rather
  than redirecting. This is intentional; do not add a proxy redirect for it.
- **C-3** 🔲 On first sign-in, a `Customer` document is created in MongoDB with a
  generated `stampToken` and `redeemToken`, and an empty `LoyaltyCard` (0 stamps).
- **C-4** 🔲 Deleting an account must actually delete the customer's DB records, not
  just sign out. (`profile/page.tsx` line ~809 currently has a TODO to this effect.)

### 3.2 Browse the menu — 🟡
- **C-5** ✅ Items display with photo, name, subtitle, price, rating, veg/non-veg mark.
- **C-6** ✅ Filter by category (All / Sandwitch / Burger / Staters / Drinks) and by
  veg / non-veg / all. Featured items surface on the home page.
- **C-7** 🔲 This list comes from `GET /api/menu`, which reads MongoDB — not from the
  imported `MOCK_MENU` array. **The visual result must be identical.**
- **C-8** 🔲 Unavailable items are visibly greyed out and cannot be added to the cart.
  An availability toggle flipped in the admin app is reflected here on next fetch.

### 3.3 Cart — ✅ built
- **C-9** ✅ Add / increment / decrement / remove items; cart persists across refreshes
  via Zustand `persist` (`sns-cart` key).
- **C-10** ✅ Prices always come from the menu data, never re-entered by the client.
- **C-11** 🔲 On checkout the server **recomputes** the total from current DB prices and
  rejects any client-supplied total that disagrees.

### 3.4 Checkout & fulfillment — 🔲
- **C-12** 🔲 Placing an order triggers a simple popup: **Dine-in** or **Pickup**.
  - **Dine-in** → an optional table-number field. The customer can enter one or leave
    it blank — it is never required to place the order.
  - **Pickup** → nothing extra; show an estimated ready time back to them.
  - 🔒 **No delivery option in this app.** Delivery is handled entirely by Zomato,
    outside this ecosystem. Do not build a delivery fulfillment type, an address
    picker, or an address book anywhere in this app.
- **C-13** 🔲 The cart currently shows a flat "Delivery fee" line; remove it entirely —
  there is no fulfillment type this app supports that charges one.
- **C-14** 🔲 Placing an order calls `POST /api/orders`, clears the cart on success, and
  routes the customer to the Orders tab.
- **C-15** 🔲 An unavailable or deleted item in the cart blocks checkout with a clear
  message naming the item.
- **C-16** 🔲 Payment is cash on collection. No payment step exists.

### 3.5 Track an order — 🟡
- **C-17** ✅ A status timeline UI with grouped sections and animation exists.
- **C-18** 🔲 Statuses simplify to **Pending → Accepted → Completed**, plus **Rejected**.
  The existing `preparing / ready / served` states are removed, not kept alongside.
- **C-19** 🔲 Orders load from `GET /api/orders/me`, not the `INITIAL_ORDERS` constant.
- **C-20** 🔲 Status changes appear on the customer's screen **within a few seconds,
  without a manual refresh**, via polling (not a real-time listener — see
  `ARCHITECTURE.md` §5.8).
- **C-21** 🔲 A rejected order shows a distinct, non-alarming rejected state.
- **C-22** 🔲 Order history (completed/rejected) is a separate tab from active orders.

### 3.6 Loyalty card — 🟡
- **C-23** ✅ Stamp-grid card UI with fill animation and a "Reward Ready" state.
- **C-24** 🔲 Stamp count comes from `GET /api/loyalty/me`.
- **C-25** 🔲 The small QR is a **real, scannable QR** encoding `stampToken`
  (replace the decorative `QR_GRID` div matrix with a QR library).
- **C-26** 🔲 When the card is full, a large QR encoding `redeemToken` becomes available
  in the redeem modal. It is **not rendered at all** before the card is full.
- **C-27** 🔲 After the admin redeems, the card resets to 0 and `redeemToken` is rotated
  server-side; the customer's screen picks this up within a few seconds via polling.
- **C-28** 🔲 Stamp increments appear live on the customer's screen within seconds of
  the admin scanning — this is the moment the whole real-time layer exists for.

### 3.7 Profile — 🟡
- **C-29** ✅ Profile UI: avatar (Google photo or cartoon picker), name, email, stats,
  preference toggles.
- **C-30** 🔲 Real data replaces `lib/mock-user-data.ts`, keeping the existing function
  signature `getRecentOrders(userEmail)` so the page barely changes.
- **C-31** 🔒 **Removed — decision: no phone number anywhere.** Google sign-in already
  gives every customer a unique, verified identity; a phone number added nothing. Do
  not collect, store, display, or require one anywhere in either app.
- **C-32** 🔒 **Removed — decision: no delivery, no address book.** The static
  "address" label in the profile UI can stay as inert display text or be removed at
  the developer's discretion; no CRUD, no backend, no address model exists.
- **C-33** 🔲 Preference toggles (veg-only, order updates, offers, new items) persist to
  the DB instead of resetting on reload.

### 3.8 Static pages — ✅ built
- **C-34** ✅ About page and Party/catering page. No backend needed.

---

## 4. Flutter admin app requirements — 🔲 all not started

### 4.1 Auth
- **A-1** One login screen: username + password → `POST /api/admin/login` → JWT stored
  in `flutter_secure_storage` (**not** SharedPreferences).
- **A-2** There is **no** signup, no forgot-password, no change-password, no account
  screen anywhere in the app. The corresponding API endpoints do not exist either.
- **A-3** Any `401` from the API clears the token and returns to the login screen.
- **A-4** Session survives app restart until the JWT expires (24h).

### 4.2 Menu tab
- **A-5** List all items with photo, name, price, and an availability switch.
- **A-6** Toggling the switch calls `PATCH /api/menu/:id/availability` and updates
  optimistically, reverting on failure.
- **A-7** Floating "+" opens a create form: name, subtitle, price, category, veg/non-veg,
  featured. **No image field in this form** — see A-10.
- **A-8** Tapping an item opens the same form pre-filled for editing (still no image
  field).
- **A-9** Delete with a confirmation dialog.
- **A-10** 🔒 **Decision: no image upload UI, anywhere, ever, in v1.** The catalog is
  small (~20–30 items) and effectively static. A new item is created without a photo
  (showing a placeholder in the UI until one is set) and shows a photo once the
  *developer* manually places the file in `public/images/`, redeploys, and sets that
  item's `image` field directly via MongoDB Atlas (or a small one-off script). This is a
  deliberate simplicity trade-off, not a gap to fill in later — do not build an upload
  picker, do not add Cloudinary, do not add any image-editing control to the admin form.

### 4.3 Loyalty tab
- **A-11** A mode switch at the top: **Add Stamp** / **Redeem**. The camera scanner sits
  below it.
- **A-12** On scan, `GET /api/loyalty/scan/:token` resolves the customer and tells the
  app which action that token is valid for.
- **A-13** If the scanned token doesn't match the selected mode (e.g. a stamp QR scanned
  in Redeem mode), show a clear error and do nothing. **Never fall back to the other
  action.**
- **A-14** After resolving, show the customer's name and card (e.g. 6/10), then
  an explicit confirm button — never act on the scan alone.
- **A-15** Redeem is only offered when `rewardReady` is true.
- **A-16** Success gives visible + haptic confirmation, then returns to scanning.

### 4.4 Orders tab
- **A-17** Segmented control: Pending / Accepted / Completed / Rejected; newest first.
- **A-18** Each card shows: fulfillment type (dine-in/pickup), table number if dine-in,
  items with quantities, customer name, total, and a relative timestamp.
- **A-19** Pending orders show **Accept** and **Reject**; Accepted show **Complete**;
  Completed and Rejected are read-only.
- **A-20** Reject requires a confirmation tap (it's irreversible).
- **A-21** A badge on the Orders tab shows the pending count.
- **A-22** A new order fires an FCM push with a **custom alert sound**, working with the
  app foregrounded, backgrounded, and killed. Tapping it deep-links to Pending.
- **A-23** Pull-to-refresh, plus a poll on tab focus as a safety net if push fails.

---

## 5. Explicitly out of scope for v1

Multi-staff logins and roles · sales/analytics dashboard · kitchen printer integration ·
customer push notifications · promo codes and discounts · Play Store release ·
multi-branch support · online payment · item variants/add-ons · scheduled orders ·
a web admin panel (the empty `app/admin/` folder is being deleted).

---

## 6. Acceptance test for v1 (the one that matters)

1. Owner adds a new item in the Flutter app with a photo → it appears on the customer
   web menu.
2. Owner toggles an item unavailable → it greys out for customers.
3. Customer builds a cart, picks **dine-in + table 4**, places the order.
4. Owner's phone rings with a custom sound **while the app is killed**; the order is in
   Pending within seconds with the right table number (if the customer gave one) and
   total.
5. Owner taps Accept → the customer's screen moves to Accepted within a few seconds,
   with no manual refresh.
6. Owner taps Complete → the customer's screen moves to Completed the same way.
7. Customer shows their stamp QR; owner scans in Add Stamp mode → the customer's card
   animates from 6/10 to 7/10 within a few seconds.
8. At 10/10 the customer's redeem QR appears; owner scans it in Redeem mode → card
   resets to 0/10 and the old redeem QR no longer works.
