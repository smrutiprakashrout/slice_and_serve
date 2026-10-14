# ARCHITECTURE.md — Slice and Serve Admin (Flutter)

This document describes the architecture of the **Flutter admin app only**.  
The customer web app and the Next.js backend are separate systems. This app is a pure client that consumes the existing REST API.

---

## 0. Stage A vs Stage B — what this document describes

This document describes the app's **full, final** architecture — both stages
combined. Per `PROJECT_CONTEXT.md` §2, Stage A builds `theme/`, `mocks/`, `screens/`,
and `widgets/` against hardcoded data with **none** of `core/`, `services/`, or
`providers/` in real use yet. Stage B fills those in and deletes `mocks/`. When a task
in `TASKS.md` references a layer, check which stage it's tagged with before assuming
that layer should exist yet.

---

## 1. System context

```
┌─────────────────────────────┐
│   Flutter Admin App         │
│   (Android only)            │
│                             │
│  • Login                    │
│  • Menu CRUD + availability │
│  • Loyalty scanner          │
│  • Orders (Accept/Reject/   │
│    Complete)                │
│  • FCM push + deep link     │
└──────────────┬──────────────┘
               │ REST + JWT
               │ FCM registration
               ▼
┌─────────────────────────────┐
│   Next.js API (Vercel)      │
│   + MongoDB Atlas           │
│   (single source of truth)  │
└─────────────────────────────┘
               ▲
               │ FCM push (new order)
               │
┌─────────────────────────────┐
│   Firebase Cloud Messaging  │
│   (notifications only)      │
└─────────────────────────────┘
```

- The admin app **never** talks to MongoDB or Firestore directly.
- The admin app **never** shares auth with the customer web app.
- All business rules (status transitions, stamp/redeem guards, total recalculation, token rotation) live on the server.

---

## 2. High-level folder structure

```
lib/
├── main.dart
├── theme/
│   └── app_theme.dart              # Brand colors, typography, radii, ThemeExtensions
├── mocks/                          # STAGE A ONLY — deleted screen-by-screen as
│   ├── mock_menu_items.dart        # Stage B wires that screen to the real API.
│   ├── mock_orders.dart            # Every file here is hardcoded Dart data, no JSON
│   └── mock_loyalty.dart           # parsing needed yet.
├── core/                           # STAGE B — doesn't exist until Stage B starts
│   ├── api_client.dart             # dio instance + JWT interceptor + 401 → logout
│   ├── secure_store.dart           # flutter_secure_storage wrapper
│   ├── result.dart                 # Result<T> success / failure wrapper
│   └── constants.dart              # API base URL, timeouts, etc.
├── models/
│   ├── menu_item.dart
│   ├── category.dart
│   ├── order.dart
│   ├── loyalty_card.dart
│   └── customer_summary.dart       # name + card progress returned by scan
├── services/                       # STAGE B
│   ├── auth_service.dart
│   ├── menu_service.dart
│   ├── order_service.dart
│   ├── loyalty_service.dart
│   └── notification_service.dart   # FCM + local notifications + deep links — Push stage
├── providers/                      # STAGE B — Riverpod
│   ├── auth_provider.dart
│   ├── menu_provider.dart
│   ├── orders_provider.dart
│   └── loyalty_provider.dart
├── screens/
│   ├── login_screen.dart
│   ├── main_shell.dart             # BottomNavigationBar: Menu | Loyalty | Orders
│   ├── menu/
│   │   ├── menu_screen.dart
│   │   └── menu_item_form.dart     # shared create + edit (no image field)
│   ├── loyalty/
│   │   ├── loyalty_scanner_screen.dart
│   │   └── loyalty_card_view.dart  # shows name + stamps after scan
│   └── orders/
│       ├── orders_screen.dart
│       └── order_card.dart
└── widgets/                        # shared buttons, cards, empty/error/loading states
```

**Strict layering rule**  
`screens/` → `providers/` → `services/` → `api_client`  
A widget must never call `dio` directly. A service must never build a widget.

---

## 3. Data models (immutable)

All models are immutable (`final` fields + `copyWith`) and implement `fromJson` / `toJson`.

### MenuItem
```dart
class MenuItem {
  final String id;
  final String name;
  final String subtitle;
  final double price;
  final String categorySlug;
  final String type;          // "veg" | "non-veg"
  final bool featured;
  final String? image;        // may be null → show placeholder
  final bool available;
  // ...
}
```

### Order
```dart
class Order {
  final String id;
  final String customerName;
  final String fulfillment;   // "dine-in" | "pickup"
  final String? tableNumber;  // only present for dine-in
  final List<OrderItem> items;
  final double total;
  final String status;        // "pending" | "accepted" | "completed" | "rejected"
  final DateTime placedAt;
  // ...
}
```

### Loyalty scan result
```dart
class LoyaltyScanResult {
  final String customerId;
  final String customerName;
  final int stamps;
  final int totalRequired;
  final bool rewardReady;
  final String action;        // "stamp" | "redeem"
}
```

No phone number, no address, no delivery fields exist on any model.

---

## 4. API contracts the app consumes

Base URL is injected (dev / production).  
Auth header: `Authorization: Bearer <jwt>` on every protected route.

| Method | Path                              | Purpose                              | Auth |
|--------|-----------------------------------|--------------------------------------|------|
| POST   | `/api/admin/login`                | Username + password → JWT            | —    |
| POST   | `/api/admin/fcm-token`            | Register / update device token       | A    |
| GET    | `/api/menu`                       | List items (+ categories)            | —    |
| GET    | `/api/categories`                 | Category list, for the form picker   | —    |
| POST   | `/api/menu`                       | Create item                          | A    |
| PUT    | `/api/menu/:id`                   | Update item                          | A    |
| DELETE | `/api/menu/:id`                   | Delete item                          | A    |
| PATCH  | `/api/menu/:id/availability`      | Toggle available                     | A    |
| GET    | `/api/orders?status=`             | Admin order list (paginated)         | A    |
| PATCH  | `/api/orders/:id/accept`          | pending → accepted                   | A    |
| PATCH  | `/api/orders/:id/reject`          | pending → rejected                   | A    |
| PATCH  | `/api/orders/:id/complete`        | accepted → completed                 | A    |
| GET    | `/api/loyalty/scan/:token`        | Resolve token → customer + action    | A    |
| POST   | `/api/loyalty/:customerId/stamp`  | +1 stamp                             | A    |
| POST   | `/api/loyalty/:customerId/redeem` | Reset card + rotate redeemToken      | A    |

Error envelope (always):
```json
{
  "error": {
    "code": "INVALID_TRANSITION",
    "message": "Cannot complete a pending order."
  }
}
```

The app must surface the `message` to the user and never assume a 2xx body on error.

---

## 5. Critical flows

### 5.1 Login
```
LoginScreen
  → AuthService.login(username, password)
  → POST /api/admin/login
  → store JWT in SecureStore
  → navigate to MainShell
```

Any later 401 → interceptor clears token → force login.

### 5.2 Availability toggle (optimistic)
```
Switch flipped
  → MenuProvider toggles local state immediately
  → MenuService.patchAvailability(id, newValue)
  → on failure: revert local state + show error snackbar
```

### 5.3 Loyalty scan
```
User selects mode (Add Stamp | Redeem)
  → mobile_scanner detects QR
  → GET /api/loyalty/scan/:token
  → if result.action != selectedMode → show error, stay on scanner
  → else show LoyaltyCardView (name + progress) + Confirm button
  → on Confirm:
        if mode == stamp → POST .../stamp
        if mode == redeem → POST .../redeem
  → success feedback + return to scanner
```

### 5.4 Order status change
```
OrderCard action button
  → confirmation dialog only for Reject
  → OrderService.accept / reject / complete
  → on success: refresh list (or optimistic update)
  → backend enforces legal transitions only
    (pending→accepted, pending→rejected, accepted→completed)
```

### 5.5 New-order push
```
Backend creates order → sends FCM to all admin tokens
  → NotificationService receives message
  → if app terminated / background: system notification with custom sound
  → on tap: deep-link → MainShell → Orders tab → Pending filter
  → if app foreground: in-app banner or snackbar + optional local notification
```

---

## 6. Notification architecture

- `firebase_messaging` for token + background/terminated handling
- `flutter_local_notifications` for the custom channel and foreground display
- Custom channel must be created at app start (before any notification can arrive)
- Raw sound asset placed in `android/app/src/main/res/raw/`
- High importance, can bypass DND only if the owner explicitly allows it
- Token is registered on every successful login and on token refresh

Deep-link payload should contain enough information to open the Orders tab with the Pending filter selected.

---

## 7. State management (Riverpod)

- `authProvider` – current JWT / logged-in state
- `menuProvider` – list of MenuItems + loading/error
- `ordersProvider` – filtered by status, with pending count derived
- `loyaltyProvider` – scanner state, last scan result, mode

All async providers expose `AsyncValue` so screens can use `.when(data:, loading:, error:)`.

No `setState` for domain data. Local UI flags (e.g. “form is submitting”) may use local state or a simple StateProvider.

---

## 8. Theming & design system

All visual tokens live in `theme/app_theme.dart` and ThemeExtensions:

- Colors (primary brown, yellow highlight, cream surfaces, semantic colors)
- Radii (cards 20–24, buttons 16–20 or full pill)
- Spacing (4 px grid)
- Typography (Playfair for headlines, geometric sans for body)
- Motion (spring curves, durations)

Widgets never hard-code colors or radii.  
The polished-flutter-ui skill is the visual source of truth.

---

## 9. Security & secrets

- JWT lives only in `flutter_secure_storage`
- API base URL is compile-time or runtime config (never hard-coded secrets)
- `google-services.json` is required for FCM and must never be committed if it contains sensitive project data (follow normal Flutter Firebase practice)
- No admin password is ever stored on device

---

## 10. What this app deliberately does **not** contain

- Any image upload or image-picker code
- Local database for orders / menu (beyond optional simple caches)
- Customer auth / Google sign-in
- Delivery, address, or phone fields
- Multi-user or role logic
- Analytics SDKs
- WebView or embedded customer app

---

**End of ARCHITECTURE.md**
