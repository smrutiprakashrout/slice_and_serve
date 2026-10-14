# ARCHITECTURE.md — Slice and Serve

---

## 1. System shape

```
┌────────────────────┐        ┌────────────────────────────┐        ┌──────────────────────────┐
│  Flutter Admin App │  REST  │   Next.js 16 App Router    │  REST  │  Customer Web App        │
│     (Android)      │◄──────►│   API routes (Vercel)      │◄──────►│  (same Next.js repo)     │
└─────────┬──────────┘        └─────────────┬──────────────┘        └────────────┬─────────────┘
          │                                 │ mongoose                            │ Auth.js v5 (Google)
          │ FCM push, admin-only            ▼                                     │ SWR polling
          │                         ┌───────────────┐                             │ (no Firestore — see §5.8)
          │                         │ MongoDB Atlas │  ← SINGLE SOURCE OF TRUTH   │
          │                         └───────────────┘                             │
          └──────────────────►  Firebase Cloud Messaging  ◄────────────────────────┘
                                  (push notifications only, Phase 9 — no Firestore)
Menu photos: bundled in `public/images/`, path set directly in Mongo by the developer.
No image host, no upload service — see §3 and §7.1 for why.
```

### Why this shape

- **MongoDB is the only source of truth.** All business rules live in the Next.js API.
  Both clients are dumb consumers.
- **The customer app gets "live" updates via polling, not Firestore.** See §5.8 for the
  decision and tradeoff. Firebase still appears in this stack, but only for FCM push
  notifications to the admin app (Phase 9) — there is no real-time database mirror.
- **Clients never write to Mongo except through the API.** One choke point = one place
  enforcing "you can't complete a pending order" and "a redeem token can't be reused."
- **Two isolated auth systems.** Customer = Auth.js Google session cookie. Admin = a
  bearer JWT with its own secret. Neither can escalate into the other.

---

## 2. Runtime notes specific to Next.js 16

- Middleware is **`proxy.ts`** at the repo root, not `middleware.ts`. Its matcher is
  currently `["/api/protected/:path*"]` and is effectively inactive.
- `auth.config.ts` must stay free of Node-only imports (no mongoose, no fs) because
  `proxy.ts` imports it into the edge runtime. **Database code belongs in `auth.ts`
  only.** Breaking this rule produces confusing edge-runtime build errors.
- All API routes that touch Mongo must run on the Node runtime (the default). Never add
  `export const runtime = "edge"` to a route that imports `lib/db.ts`.
- Before writing any routing/middleware/config code, consult
  `node_modules/next/dist/docs/` — this Next version differs from most training data
  (see the repo's own `AGENTS.md`).

---

## 3. Data model (MongoDB via Mongoose, in `model/`)

```ts
// model/Customer.ts — upserted in auth.ts jwt callback on first Google sign-in
Customer {
  _id
  googleId: string          // unique, indexed
  name: string
  email: string             // unique, indexed
  // 🔒 no `phone` field — decision: Google sign-in's unique identity is sufficient;
  // no phone number anywhere in either app. See §5.7.
  photo?: string
  // 🔒 no `addresses` field — decision: this app never supports delivery or a
  // saved address book. Delivery is handled entirely by Zomato, outside this
  // ecosystem. See §5.6.
  preferences: { vegOnly, orderUpdates, offers, newItems }   // all boolean
  stampToken: string        // unique, indexed, STABLE — everyday QR
  redeemToken: string       // unique, indexed, ROTATED on every redemption
  createdAt, updatedAt
}

// model/Category.ts
Category { _id, name, slug (unique), icon, sortOrder }

// model/MenuItem.ts — same field names as lib/menu-data.ts, to keep the UI unchanged
MenuItem {
  _id, name, subtitle, price: number, rating: number,
  categorySlug: string (indexed),
  type: "veg" | "non-veg",
  featured: boolean,
  image: string,            // path under /public/images, e.g. "/images/burger.jpg"
                             // set manually by the developer via Atlas — see §7.1.
                             // keep the key `image`, NOT `imageUrl`
  available: boolean,
  createdAt, updatedAt
}

// model/LoyaltyCard.ts — created alongside the Customer
LoyaltyCard {
  _id, customerId (unique, indexed, ref Customer),
  stamps: number (default 0),
  totalRequired: number (default 10),
  rewardReady: boolean (default false),
  updatedAt
}

// model/Order.ts
Order {
  _id, customerId (indexed, ref Customer),
  customerName,                          // snapshot at order time; 🔒 no customerPhone
  fulfillment: "dine-in" | "pickup",     // 🔒 no "delivery" — see §5.6
  tableNumber?: string,                  // dine-in only
  items: [{ menuItemId, name, price, quantity }],             // price snapshot
  itemTotal: number, total: number,      // 🔒 no deliveryFee — see §5.6
  status: "pending" | "accepted" | "completed" | "rejected",
  placedAt (indexed desc), updatedAt
}

// model/Admin.ts — exactly one document, inserted by a one-off script
Admin { _id, username (unique), passwordHash, fcmTokens: [string] }
```

### Schema rules

- **Snapshot, don't join.** An order stores item names, prices, and the customer's name
  as they were *at order time*. Renaming a menu item later must not rewrite order
  history.
- **Keep `image` as the field name** on `MenuItem`. `lib/menu-data.ts` and every UI
  component already use `image`; renaming it to `imageUrl` would force UI edits for no
  benefit.
- **Indexes to create:** `Customer.googleId`, `Customer.email`, `Customer.stampToken`,
  `Customer.redeemToken`, `MenuItem.categorySlug`, `Order.customerId`,
  `Order.status + placedAt`, `LoyaltyCard.customerId`.

### No Firestore mirror — see §5.8

This project originally planned a Firestore real-time mirror here. That's been cut in
favor of polling; there is no second data store, no mirror schema, and no security
rules to maintain. MongoDB is the only place order and loyalty state lives.

---

## 4. API contract

Base: the deployed Vercel URL. Auth column: **S** = customer Auth.js session,
**A** = admin bearer JWT, **—** = public.

| Method | Path | Auth | Purpose | Status |
|---|---|---|---|---|
| GET/POST | `/api/auth/[...nextauth]` | — | Google sign-in | ✅ built |
| POST | `/api/admin/login` | — | Admin JWT login (rate-limited) | 🔲 |
| POST | `/api/admin/fcm-token` | A | Register admin device token | 🔲 |
| GET | `/api/menu` | — | `?category=&type=&available=` → `{categories, items}` | 🟡 route built, mock data |
| GET | `/api/categories` | — | Category list | 🔲 |
| POST | `/api/menu` | A | Create item | 🔲 |
| PUT | `/api/menu/:id` | A | Edit item | 🔲 |
| DELETE | `/api/menu/:id` | A | Delete item | 🔲 |
| PATCH | `/api/menu/:id/availability` | A | Toggle availability | 🔲 |
| GET | `/api/me` | S | Current customer profile | 🔲 |
| PATCH | `/api/me` | S | Update preferences | 🔲 |
| DELETE | `/api/me` | S | Delete account + data | 🔲 |
| GET | `/api/loyalty/me` | S | Current customer's card + `stampToken` (+ `redeemToken` **only if** `rewardReady`) | 🔲 |
| GET | `/api/loyalty/scan/:token` | A | Resolve token → customer, card, and `action: "stamp" \| "redeem"` | 🔲 |
| POST | `/api/loyalty/:customerId/stamp` | A | +1 stamp | 🔲 |
| POST | `/api/loyalty/:customerId/redeem` | A | Reset card, rotate `redeemToken`, mirror | 🔲 |
| POST | `/api/orders` | S | Place order (server recomputes total) | 🔲 |
| GET | `/api/orders/me` | S | Customer's own orders | 🔲 |
| GET | `/api/orders?status=` | A | Admin order list | 🔲 |
| PATCH | `/api/orders/:id/accept` | A | pending → accepted | 🔲 |
| PATCH | `/api/orders/:id/reject` | A | pending → rejected | 🔲 |
| PATCH | `/api/orders/:id/complete` | A | accepted → completed | 🔲 |
| GET | `/api/health` | — | Uptime probe | 🔲 |

### Response envelope

Success returns the resource directly. Errors always return:

```json
{ "error": { "code": "INVALID_TRANSITION", "message": "Cannot complete a pending order." } }
```

Status codes: `400` validation · `401` missing/invalid auth · `403` wrong auth type ·
`404` not found · `409` invalid state transition · `429` rate-limited · `500` server.

### Preserve the existing `/api/menu` contract

`GET /api/menu` already returns `{ categories, items }` with a
`Cache-Control: public, max-age=60, stale-while-revalidate=300` header and three
optional AND-combining filters. When its data source swaps to Mongo, **the shape, the
params, and the header must stay byte-identical** — the Flutter app will be written
against this contract too.

---

## 5. Critical flows

### 5.1 Placing an order

```
Customer taps "Place Order"
  → POST /api/orders { items:[{menuItemId, quantity}], fulfillment, tableNumber? }
  → server: auth() → resolve Customer
  → server: load each MenuItem from Mongo; reject if missing or unavailable (409)
  → server: RECOMPUTE itemTotal / total from DB prices (ignore client totals)
  → server: validate fulfillment-specific fields (dine-in's tableNumber is optional —
            never reject an order for lacking one; pickup requires nothing extra)
  → server: insert Order { status: "pending" }
  → server: send FCM to every Admin.fcmTokens entry (custom sound channel)
  → 201 { order }
  → client: clear cart, route to Orders
```

### 5.2 Admin changes order status

```
Flutter taps Accept
  → PATCH /api/orders/:id/accept  (Bearer admin JWT)
  → server: verify admin JWT
  → server: guard the transition — only pending→accepted, pending→rejected,
            accepted→completed are legal. Anything else → 409 INVALID_TRANSITION.
            (Explicitly: pending→completed must fail.)
  → server: update Mongo
  → customer's Orders page picks up the change on its next poll (§5.8) — within a
    few seconds while the page is open, not instantly
```

### 5.3 Loyalty stamp

```
Admin selects "Add Stamp" mode, scans QR
  → GET /api/loyalty/scan/:token
  → server: look up Customer by stampToken OR redeemToken
  → server: return { customer, card, action: "stamp" | "redeem" }   // which one matched
  → Flutter: if action !== selected mode → show error, STOP (never auto-switch)
  → Flutter shows card, admin confirms
  → POST /api/loyalty/:customerId/stamp
  → server: stamps += 1; if stamps >= totalRequired → rewardReady = true
  → customer's loyalty page picks up the new count on its next poll (§5.8)
```

### 5.4 Loyalty redeem (and why tokens rotate)

```
Card is full → customer's app fetches /api/loyalty/me, which now also returns redeemToken
  → large QR renders in the redeem modal
Admin selects "Redeem" mode, scans it
  → GET /api/loyalty/scan/:token → action: "redeem"
  → POST /api/loyalty/:customerId/redeem
  → server: guard rewardReady === true, else 409
  → server: stamps = 0, rewardReady = false, ROTATE Customer.redeemToken to a new value
  → the screenshot the customer took of the old redeem QR is now dead
```

This is the entire reason for two tokens. The everyday `stampToken` is exposed
constantly and is harmless if copied — it can only add stamps. The `redeemToken` is
high-value, exposed briefly, and single-use by rotation.

---

## 5.5 Menu images — deliberately manual (no upload pipeline)

**Decision:** the admin app has no image upload feature. This is not a v1 shortcut to
revisit later — it's a permanent choice for this project's scale.

**Why:** the menu is ~20–30 items and changes rarely (the owner confirmed items stay
stable for years, not weeks). A dynamic upload pipeline (Cloudinary, Vercel Blob, or
otherwise) adds an external service, a signed-upload endpoint, a picker UI, and a whole
class of upload-failure edge cases — all to solve a problem that happens a few times a
year. It's not worth it here, and there's also a hosting-shape reason it wouldn't even
work simply: Vercel's serverless functions have an ephemeral, read-only filesystem, so
an API route could never save an uploaded file to `public/` and have it persist anyway.

**How it actually works:**
1. Photos ship as static files in `public/images/` (already the case today — see
   `lib/menu-data.ts`'s existing `MOCK_MENU` image paths).
2. The Flutter "add item" / "edit item" form has **no image field at all** — `MenuItem`
   is created/edited via `POST`/`PUT /api/menu` without one. A `MenuItem` with no
   `image` set renders a placeholder image in both apps until one is assigned.
3. When a genuinely new photo is needed: the developer adds the file to
   `public/images/`, redeploys, then sets that item's `image` field directly —
   via MongoDB Atlas's UI, or a tiny one-off script — to the matching path
   (e.g. `/images/new-item.jpg`).
4. Both apps just read whatever string is in `image` and render it. Neither app
   validates that the file actually exists at that path — a typo here is a developer
   mistake caught visually (broken image icon), not something the API guards against.

**What this means for tasks downstream:** P3-10 (originally a Cloudinary
signed-upload endpoint) is removed from the roadmap. A-7/A-10 in `PRD.md` reflect the
image-less admin form. `upload_service.dart` is removed from the Flutter structure in
§7.1.

---

## 5.6 No delivery, no address book (decision)

**Decision:** this app supports exactly two fulfillment types — **dine-in** and
**pickup**. There is no delivery fulfillment type, no delivery fee, no saved-address
book, and no address CRUD anywhere in either app. Customers who want delivery use
Zomato, entirely outside this ecosystem.

**Why:** the shop doesn't run its own delivery — it lists on Zomato for that. Building
address management, a delivery-fee calculation, and a delivery-address snapshot on
every order would be solving a problem this shop has already outsourced. It's dead
weight, not a v1-vs-later tradeoff.

**What this removes from the original spec:** `Customer.addresses[]`,
`Order.deliveryAddress`, `Order.deliveryFee`, the `"delivery"` value of
`Order.fulfillment`, the `/api/me/addresses` endpoints, and the checkout address picker.
The cart's "Delivery fee" line is removed outright, not made conditional. The profile
page's address section either goes away or stays as inert static text — no backend
supports it.

**If this ever changes** (e.g. the shop starts delivering in-house later), it re-enters
as new scope with its own schema additions — don't half-build it now against a
guess at what that would look like.

---

## 5.7 No phone number anywhere (decision)

**Decision:** neither app collects, stores, displays, or requires a customer phone
number. `Customer.phone` and `Order.customerPhone` don't exist.

**Why:** Google sign-in already gives every customer a stable, unique, verified
identity (`googleId`). A phone number would only have mattered for delivery driver
coordination — and there is no in-app delivery (§5.6) — or as a spoken identifier for
pickup orders, which a customer's name already serves just as well.

**What this removes from the original spec:** the phone-collection UI flow, phone
validation in `PATCH /api/me`, `customerPhone` on every order snapshot, and the phone
line in the admin app's loyalty-scan result and order cards (both now show name only).

---

## 5.8 No Firestore — polling instead (decision)

**Decision:** the customer web app does not use Firestore or any real-time listener.
Order status and loyalty stamp updates are picked up via **SWR polling** — the Orders
and Loyalty pages re-fetch on a short interval (and on tab focus) while mounted, giving
updates within a few seconds rather than truly instantly.

**Why:** Firestore's whole purpose in the original design was working around Vercel
serverless having no persistent connections. Polling solves the same underlying
problem — "how does the customer see a change without manually refreshing" — with one
fewer service, no security rules to maintain, no client-side Firebase SDK, and no
separate data store that could ever drift from MongoDB. The cost is a few seconds of
lag instead of instant push, which is an acceptable trade for a single small shop.

**What this removes from the original spec:** the entire Firestore mirror schema,
`lib/firebase-admin.ts`, `lib/firebase-client.ts`, every "mirror to Firestore" step in
§5.1–5.4, Firestore security rules, and the `NEXT_PUBLIC_FIREBASE_*` client env vars.

**What stays:** Firebase Cloud Messaging (FCM), for push notifications to the admin
app only (Phase 9). That's a separate Firebase product from Firestore and doesn't
require Firestore to be enabled — the Firebase project just needs Cloud Messaging
turned on, not the Firestore database.

---

## 6. Auth implementation

### Customer (existing — don't change its behavior)
Auth.js v5, Google provider, `session: { strategy: "jwt" }`. The `jwt` callback copies
`user.id` into the token; the `session` callback exposes `session.user.id`.
**Phase 4 adds a Mongo upsert inside the `jwt` callback** (only when `user` is present,
i.e. first sign-in) and swaps `token.id` to the Mongo `_id`. Keep JWT strategy — no
database adapter.

Server routes read the session with `auth()` from `@/auth` on the Node runtime.

### Admin (new)
`POST /api/admin/login` → bcrypt-compare against the single `Admin` doc → sign a JWT
with `ADMIN_JWT_SECRET` (24h). Every admin route calls a shared `requireAdmin(req)`
helper in `lib/admin-auth.ts` that verifies the `Authorization: Bearer` header and
returns the admin, or throws a 401. Login is rate-limited (e.g. 5 attempts / 15 min per
IP). No admin creation, reset, or management endpoint exists anywhere.

---

## 7. Flutter admin app structure

```
lib/
  main.dart
  theme/app_theme.dart              # brand colors, Playfair headings, rounded shapes
  core/
    api_client.dart                 # dio + JWT interceptor + 401 → logout
    secure_store.dart               # flutter_secure_storage wrapper
    result.dart                     # typed success/failure wrapper
  models/  menu_item.dart, order.dart, loyalty_card.dart, customer.dart
  services/
    auth_service.dart
    menu_service.dart
    order_service.dart
    loyalty_service.dart
    notification_service.dart       # FCM, custom sound channel, deep links
  providers/                        # Riverpod
    auth_provider.dart, menu_provider.dart, orders_provider.dart, loyalty_provider.dart
  screens/
    login_screen.dart
    main_shell.dart                 # bottom nav: Menu / Loyalty / Orders
    menu/menu_screen.dart, menu_item_form.dart
    loyalty/loyalty_scanner_screen.dart, loyalty_card_view.dart
    orders/orders_screen.dart, order_card.dart
  widgets/                          # shared brand buttons, cards, empty states
```

**Packages:** `dio`, `flutter_riverpod`, `flutter_secure_storage`, `firebase_core`,
`firebase_messaging`, `flutter_local_notifications` (custom sound channel),
`mobile_scanner`, `intl`, `google_fonts`. (No `image_picker` — see §5.5, the admin app
never uploads images.)

**Android notification channel:** a custom high-importance channel with a raw sound
asset is required — a default FCM notification will not reliably make noise when the app
is killed.

---

## 8. Deployment

1. MongoDB Atlas M0 cluster → connection string → `MONGODB_URI`.
2. Firebase project (Phase 9, needed only for push notifications) → enable **Cloud
   Messaging only** — Firestore is not used, don't enable it → generate a service
   account key → split into `FIREBASE_PROJECT_ID` / `CLIENT_EMAIL` / `PRIVATE_KEY`.
3. Vercel → import the repo, set every env var, deploy.
4. Run the seed script once: inserts categories + menu items from `lib/menu-data.ts`,
   and the single `Admin` document with a bcrypt-hashed password.
5. Flutter: drop in `google-services.json`, set the production API base URL, add the raw
   sound asset, `flutter build apk --release` with the signing key, sideload.

*(No Cloudinary step — see §5.5. Menu photos are static files in `public/images/`,
deployed with the rest of the app.)*

**Monitoring:** Vercel function logs and error rate · Atlas metrics (watch M0 storage
and connection caps) · Firebase console for FCM delivery stats · UptimeRobot pinging
`/api/health`.

---

## 9. Free-tier constraints that shape design

- **Serverless reuses containers** → `lib/db.ts` must cache the mongoose connection on
  `globalThis`, or Atlas M0's connection limit will be exhausted.
- **Polling has a cost too, just a different one** — every open Orders/Loyalty page
  re-fetches on an interval (Phase 7), which is DB reads, not Firestore reads. Keep the
  interval sensible (a handful of seconds, not sub-second) and pause it when the tab
  isn't visible — see Phase 7's tasks.
- **M0 has limited storage** → completed orders older than ~6 months can be pruned
  later; not a v1 concern.
