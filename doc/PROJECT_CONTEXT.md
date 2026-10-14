# PROJECT_CONTEXT.md

> **Read this file first.** It is the orientation doc for any human or AI agent
> joining this project. It tells you what exists, what doesn't, and what the
> non-negotiable rules are. Everything else (PRD, ARCHITECTURE, CODING_STANDARDS,
> TASKS) assumes you have read this.

---

## 1. What this project is

**Slice and Serve** is a fast-food shop ecosystem made of **two apps sharing one backend**:

| App | Stack | Status | Audience |
|---|---|---|---|
| **Customer web app** | Next.js 16 (App Router) + React 19 + Tailwind v4 | UI complete, backend not started | Public customers |
| **Admin app** | Flutter (Android only) | Not started | Shop owner/staff (1 person) |
| **Backend** | Next.js API routes on Vercel + MongoDB Atlas | ~5% built | Both apps |

The customer app is an existing repo (`slice_and_serve`). The Flutter app is a separate
repo that does not exist yet. They talk to the **same** Next.js API.

---

## 2. The single most important fact about this codebase

**The entire customer web app is a beautiful, finished, fully-mocked front end with
almost no backend behind it.**

- Every screen is built and polished (~4,700 lines of TSX).
- Menu data is a hardcoded array in `lib/menu-data.ts`.
- Orders are a hardcoded array + `useState` in `app/(customer)/orders/page.tsx`.
- Loyalty stamps are a hardcoded object; the "QR code" is a **decorative grid of
  divs**, not a scannable code.
- Profile data comes from `lib/mock-user-data.ts`.
- `model/` exists and is **empty**. There is no database connection anywhere.
- The only real integrations that work: **Google sign-in (Auth.js v5)** and
  **`GET /api/menu`** (which serves the mock array over HTTP).

So the work ahead is **not** "build the app." It is **"replace mocks with a real
backend, without touching the UI."** That distinction shapes every task in TASKS.md.

---

## 3. Current repo map

```
slice_and_serve/
├── app/
│   ├── (customer)/              # tabbed shell w/ BottomNav
│   │   ├── page.tsx             # home/menu  — imports MOCK_MENU directly ❌
│   │   ├── loyalty/page.tsx     # stamp card — fake QR ❌
│   │   ├── orders/page.tsx      # order track — INITIAL_ORDERS const ❌
│   │   ├── about/page.tsx       # static ✅
│   │   └── party/page.tsx       # static ✅
│   ├── (standalone)/            # no bottom nav
│   │   ├── login/page.tsx       # Google sign-in ✅ real
│   │   ├── cart/page.tsx        # Zustand cart ✅ real (localStorage)
│   │   └── profile/page.tsx     # mock user data ❌
│   ├── api/
│   │   ├── auth/[...nextauth]/  # ✅ real
│   │   └── menu/route.ts        # ✅ real route, ❌ mock data source
│   ├── admin/                   # EMPTY — delete
│   ├── kitchen/                 # EMPTY — delete
│   └── components/              # BottomNav, TopBar ✅
├── lib/
│   ├── menu-data.ts             # MOCK_MENU + CATEGORIES (becomes the DB seed)
│   ├── cart-store.ts            # Zustand + persist ✅ keep as-is
│   ├── mock-user-data.ts        # ❌ to be deleted in Phase 4
│   └── useScrollDirection.ts    # ✅
├── model/                       # EMPTY — Mongoose models go here
├── auth.ts / auth.config.ts     # Auth.js v5, edge-safe split ✅
├── proxy.ts                     # Next 16 replaces middleware.ts; matcher is
│                                #   /api/protected/* only (effectively inactive)
└── types/next-auth.d.ts         # session.user.id augmentation ✅
```

### Things that will surprise you
- **`proxy.ts`, not `middleware.ts`.** This is Next.js 16. `AGENTS.md` in the repo warns
  that this Next version has breaking changes vs. what most models were trained on.
  **Read `node_modules/next/dist/docs/` before writing routing/middleware code.**
- **`app/admin/` and `app/kitchen/` are empty decoys.** There is no web admin panel.
  Admin is Flutter-only. Delete these folders so no agent "helpfully" fills them in.
- **There are two separate auth systems** and they must never be merged:
  customer = Auth.js Google session; admin = a hand-rolled JWT for the Flutter app.
- **The repo has a known TypeScript error right now** (`totalOrders` destructured from
  `MOCK_LOYALTY`, which doesn't define it). `npm run build` will fail until fixed. This
  is task `P0-1`.

---

## 4. Non-negotiable product decisions (already settled — do not relitigate)

1. **MongoDB Atlas is the only source of truth.** Every write from either app goes
   through the Next.js API into Mongo first.
2. **No Firestore.** The customer app gets order/loyalty updates via SWR polling, not a
   real-time database mirror. Firebase still appears in this stack, but only for Cloud
   Messaging (push notifications to the admin app, Phase 9) — Firestore itself is not
   used. See `ARCHITECTURE.md` §5.8.
3. **Neither client app ever writes to Mongo directly.** Only the Next.js backend does.
4. **Order statuses are exactly four:** `pending → accepted → completed`, plus
   `rejected`. The current web UI has `pending/preparing/ready/served` — that gets
   **simplified**, not extended.
5. **Two loyalty QR tokens per customer**, and this is deliberate:
   - `stampToken` — stable, shown routinely, only valid for adding a stamp.
   - `redeemToken` — **rotated after every redemption**, shown only when the card is
     full, only valid for redeeming.
   This prevents a screenshot of a customer's everyday QR from being replayed to claim
   a free reward.
6. **Cash only.** No payment gateway, ever, in v1.
7. **Fulfillment is dine-in or pickup only — no delivery, no address book.** The shop
   delivers via Zomato, entirely outside this app; this system never models delivery
   fulfillment, a delivery fee, or a saved-address CRUD. See `ARCHITECTURE.md` §5.6.
8. **No phone number anywhere.** Google sign-in's unique identity is enough — no
   `Customer.phone`, no `Order.customerPhone`, no phone-collection UI, no phone shown
   in the admin app's order cards or loyalty scan result. See `ARCHITECTURE.md` §5.7.
9. **No image upload pipeline.** Menu photos are static files in `public/images/`;
   the developer sets an item's `image` path directly in MongoDB. No Cloudinary, no
   upload UI, ever. See `ARCHITECTURE.md` §5.5.
10. **One admin account, inserted by hand into Mongo.** No signup, no password reset,
    no admin management UI, no admin-creation API endpoint. This is a security feature.
11. **Distribution is a sideloaded signed APK.** No Play Store in v1.
12. **Free tiers throughout:** Vercel Hobby, MongoDB M0, Firebase (Cloud Messaging only,
    free with no meaningful cap for this scale).

---

## 5. Brand identity (both apps must match)

| Token | Value |
|---|---|
| Primary ink | `#3d1a00` (dark brown) |
| Highlight | `#facc15` (`bg-yellow-400`) |
| Card cream | `#fff1e3` (also `#f0d9b5`, `#f0e6dc` on older pages) |
| Headline font | Playfair Display, black weight |
| Body font | Inter |
| Shape | `rounded-2xl` → `rounded-[28px]`, soft blurred ambient glows |
| Interaction | Buttons scale down slightly on tap (not Material ripple) |
| Logo | `/images/logo.png` |

The Flutter app must carry this over: brown app bar and active tab, yellow badges,
cream cards instead of Material white, bold rounded buttons with tap-scale.

---

## 6. Environment variables

Create `.env.example` (committed) and `.env.local` (gitignored, never shared):

```bash
# Customer auth (Auth.js v5) — ALREADY IN USE
AUTH_SECRET=
AUTH_GOOGLE_ID=
AUTH_GOOGLE_SECRET=

# Database
MONGODB_URI=

# Admin auth (Flutter app) — separate from customer auth
ADMIN_JWT_SECRET=
ADMIN_JWT_EXPIRY=24h

# Firebase Admin SDK (backend → FCM push only, Phase 9 — no Firestore, see
# ARCHITECTURE.md §5.8)
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
```

*(No `NEXT_PUBLIC_FIREBASE_*` client keys — the customer app never talks to Firebase
directly; it only polls the Next.js API. Firebase is admin-app/backend-only now.)*

> ⚠️ **Security note:** live Google OAuth credentials were present in the `.env.local`
> that shipped inside the shared project zip. `.env*` *is* correctly gitignored, but the
> zip bypassed that. **Rotate `AUTH_GOOGLE_SECRET` and `AUTH_SECRET` in Google Cloud
> Console before going live** (task `P0-2`), and never include `.env.local` in an
> exported archive again.

---

## 7. How to use the doc set

| Doc | Answers |
|---|---|
| `PROJECT_CONTEXT.md` (this) | What is this, what exists, what are the rules |
| `PRD.md` | What each feature must do, from the user's point of view |
| `ARCHITECTURE.md` | How the pieces fit, schemas, API contract, data flows |
| `CODING_STANDARDS.md` | How code must be written, named, and structured |
| `TASKS.md` | **The ordered to-do list. This is your daily driver.** |

**Workflow:** open `TASKS.md`, take the top unchecked task, read the docs it references,
do it, tick it, commit. One task per commit. Do not batch.
