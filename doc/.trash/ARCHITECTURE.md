# ARCHITECTURE.md — Slice and Serve

---

## 1. System shape

```
┌────────────────────┐        ┌────────────────────────────┐        ┌──────────────────────────┐
│  Flutter Admin App │  REST  │   Next.js 16 App Router    │  REST  │  Customer Web App        │
│     (Android)      │◄──────►│   API routes (Vercel)      │◄──────►│  (same Next.js repo)     │
└─────────┬──────────┘        └─────────────┬──────────────┘        └────────────┬─────────────┘
          │                                 │ mongoose                            │ Auth.js v5 (Google)
          │ FCM push in                     ▼                                     │ SWR fetching
          │                         ┌───────────────┐                             │ Firestore listener (read-only)
          │                         │ MongoDB Atlas │  ← SINGLE SOURCE OF TRUTH   │
          │                         └───────┬───────┘                             │
          │                                 │ backend mirrors 2 fields on change  │
          │                                 ▼                                     │
          │                  ┌──────────────────────────────────┐                 │
          └──────────────────┤  Firebase (Firestore + FCM)      ├─────────────────┘
                             └──────────────────────────────────┘
              Cloudinary — menu image hosting (URL stored in Mongo, read by both apps)
```

### Why this shape

- **MongoDB is the only source of truth.** All business rules live in the Next.js API.
  Both clients are dumb consumers.
- **Firestore is a real-time mirror, not a database.** Vercel serverless functions can't
  hold a WebSocket, but the customer app must feel instant. So the backend writes two
  tiny mirror docs and the web app subscribes. If Firestore were wiped, nothing would be
  lost — it can be rebuilt from Mongo.
- **Clients never touch Firestore or Mongo for writes.** One choke point = one place
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
  phone?: string            // collected on profile; required before first order
  photo?: string
  addresses: [{
    _id, label, line1, line2?, city, pincode, isDefault: boolean
  }]
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
  image: string,            // Cloudinary URL (keep the key `image`, NOT `imageUrl`)
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
  customerName, customerPhone,           // snapshot at order time
  fulfillment: "dine-in" | "pickup" | "delivery",
  tableNumber?: string,                  // dine-in only
  deliveryAddress?: { label, line1, line2?, city, pincode },  // snapshot, delivery only
  items: [{ menuItemId, name, price, quantity }],             // price snapshot
  itemTotal: number, deliveryFee: number, total: number,
  status: "pending" | "accepted" | "completed" | "rejected",
  placedAt (indexed desc), updatedAt
}

// model/Admin.ts — exactly one document, inserted by a one-off script
Admin { _id, username (unique), passwordHash, fcmTokens: [string] }
```

### Schema rules

- **Snapshot, don't join.** An order stores item names, prices, the customer's name and
  phone, and the full delivery address as they were *at order time*. Renaming a menu
  item later must not rewrite order history.
- **Keep `image` as the field name** on `MenuItem`. `lib/menu-data.ts` and every UI
  component already use `image`; renaming it to `imageUrl` would force UI edits for no
  benefit.
- **Indexes to create:** `Customer.googleId`, `Customer.email`, `Customer.stampToken`,
  `Customer.redeemToken`, `MenuItem.categorySlug`, `Order.customerId`,
  `Order.status + placedAt`, `LoyaltyCard.customerId`.

### Firestore mirror (real-time layer only)

```
orders/{orderId}          → { status, updatedAt }
loyaltyCards/{customerId} → { stamps, totalRequired, rewardReady, updatedAt }
```

**Security rules:** a signed-in customer may `read` only their own two docs. `write` is
denied to every client; only the backend's Firebase Admin SDK service account writes.

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
| POST | `/api/upload/signature` | A | Cloudinary signed-upload params | 🔲 |
| GET | `/api/me` | S | Current customer profile | 🔲 |
| PATCH | `/api/me` | S | Update phone/preferences | 🔲 |
| DELETE | `/api/me` | S | Delete account + data | 🔲 |
| GET/POST | `/api/me/addresses` | S | List / add address | 🔲 |
| PUT/DELETE | `/api/me/addresses/:id` | S | Edit / remove address | 🔲 |
| GET | `/api/loyalty/me` | S | Current customer's card + `stampToken` (+ `redeemToken` **only if** `rewardReady`) | 🔲 |
| GET | `/api/loyalty/scan/:token` | A | Resolve token → customer, card, and `action: "stamp" \| "redeem"` | 🔲 |
| POST | `/api/loyalty/:customerId/stamp` | A | +1 stamp, mirror to Firestore | 🔲 |
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
  → POST /api/orders { items:[{menuItemId, quantity}], fulfillment, tableNumber?, addressId? }
  → server: auth() → resolve Customer
  → server: load each MenuItem from Mongo; reject if missing or unavailable (409)
  → server: RECOMPUTE itemTotal / deliveryFee / total from DB prices (ignore client totals)
  → server: validate fulfillment-specific fields (dine-in needs table, delivery needs address)
  → server: insert Order { status: "pending" }
  → server: write Firestore orders/{id} = { status:"pending", updatedAt }
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
  → server: update Mongo, then write Firestore orders/{id} = { status, updatedAt }
  → customer's open listener fires → UI moves with no refresh
```

Firestore is written **after** the Mongo write succeeds, never before, never instead.
If the Firestore write fails, log it and still return success — the customer will see the
change on their next fetch. Mongo is truth; the mirror is best-effort.

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
  → server: mirror to Firestore loyaltyCards/{customerId}
  → customer's card animates live
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
  → server: mirror to Firestore
  → the screenshot the customer took of the old redeem QR is now dead
```

This is the entire reason for two tokens. The everyday `stampToken` is exposed
constantly and is harmless if copied — it can only add stamps. The `redeemToken` is
high-value, exposed briefly, and single-use by rotation.

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
    upload_service.dart             # Cloudinary signed upload
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
`mobile_scanner`, `image_picker`, `intl`, `google_fonts`.

**Android notification channel:** a custom high-importance channel with a raw sound
asset is required — a default FCM notification will not reliably make noise when the app
is killed.

---

## 8. Deployment

1. MongoDB Atlas M0 cluster → connection string → `MONGODB_URI`.
2. Firebase project → enable Firestore + Cloud Messaging → generate a service account
   key → split into `FIREBASE_PROJECT_ID` / `CLIENT_EMAIL` / `PRIVATE_KEY`.
   Publish the Firestore security rules from §3.
3. Cloudinary free account → cloud name, API key, secret.
4. Vercel → import the repo, set every env var, deploy.
5. Run the seed script once: inserts categories + menu items from `lib/menu-data.ts`,
   and the single `Admin` document with a bcrypt-hashed password.
6. Flutter: drop in `google-services.json`, set the production API base URL, add the raw
   sound asset, `flutter build apk --release` with the signing key, sideload.

**Monitoring:** Vercel function logs and error rate · Atlas metrics (watch M0 storage
and connection caps) · Firebase console for Firestore quota and FCM delivery ·
UptimeRobot pinging `/api/health`.

---

## 9. Free-tier constraints that shape design

- **Vercel serverless has no persistent connections** → hence Firestore as the real-time
  layer instead of WebSockets.
- **Serverless reuses containers** → `lib/db.ts` must cache the mongoose connection on
  `globalThis`, or Atlas M0's connection limit will be exhausted.
- **Firestore has a daily free read quota** → listeners must subscribe only to orders
  currently on screen and must unsubscribe on unmount. Never mount a listener on the
  whole `orders` collection.
- **M0 has limited storage** → completed orders older than ~6 months can be pruned
  later; not a v1 concern.
