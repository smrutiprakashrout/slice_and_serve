# PROJECT_CONTEXT.md — Slice and Serve Admin (Flutter)

> **Read this file first.**  
> This is the single orientation document for any human or AI agent working on the **Flutter admin app only**.  
> The customer web app is a completely separate codebase and is out of scope here.  
> Everything else (PRD, ARCHITECTURE, CODING_STANDARDS, TASKS) assumes you have read this.

---

## 1. What this project is

**Slice and Serve Admin** is a single-purpose Android app used by the shop owner (one account) to run the entire daily operation of a small fast-food shop.

| Responsibility              | Status          | Notes |
|-----------------------------|-----------------|-------|
| Login (username + password) | Not started     | JWT stored securely |
| Menu management             | Not started     | List + availability toggle + add/edit/delete |
| Loyalty scanner             | Not started     | Stamp / Redeem modes + camera + confirm |
| Orders management           | Not started     | Pending → Accepted → Completed / Rejected |
| Push notifications (FCM)    | Not started     | Custom sound, works when app is killed |
| Offline / error / empty states | Required     | Every screen must handle them |

The app talks **only** to the existing Next.js backend via REST.  
It never writes to MongoDB, never talks to the customer web app, and never stores business data locally beyond the JWT and a few UI preferences.

**Success for v1** = the owner can run the shop from one Android phone: toggle menu items, scan loyalty QRs, accept/reject/complete orders, and get woken up by a new-order notification even when the app is killed.

---

## 2. The build is split into two stages — read this before touching TASKS.md

This is not optional structure — it's the single most important fact about how this
app gets built, and it applies to every task in `TASKS.md`.

### Stage A — Frontend-only demo shell
Every screen gets built and made navigable, running entirely on **hardcoded mock data**.
Zero API calls. Zero `dio` usage. The goal is purely: does this look and feel right, is
navigation right, does the brand translation from the web app feel convincing. **Stage
A is done when the person building this is genuinely happy with how it looks and
feels — a subjective, iterative checkpoint, not just a checked box.**

### Stage B — Real backend wiring
Only after Stage A is approved: screen by screen, swap mock data for real calls to the
already-built backend, following the exact contract in `ARCHITECTURE.md` §4.

**Why this order:** design decisions (spacing, color, motion, component shape) are
expensive to redo once real data and API error-handling are tangled into the same
code. Nail the look on fake data first; the wiring phase then becomes pure plumbing
with zero aesthetic decisions left to make.

**What this means practically:**
- During Stage A: never ask "should this call the API yet" — the answer is always no.
- During Stage B: never restyle anything — match what Stage A already got approved,
  exactly.
- `TASKS.md` marks every task `[A]` or `[B]` for this reason. All `[A]` tasks come
  before any `[B]` task, full stop, even if a `[B]` task looks quick.

---

## 3. The single most important facts

1. **This is a brand-new Flutter project.** There is no existing code. You are scaffolding and building everything.
2. **The backend API is already fully built and tested** — this isn't a "will exist
   eventually" situation. Every endpoint in `ARCHITECTURE.md` §4's table is live. You
   consume contracts; you do not invent new endpoints or change response shapes. You
   just don't *call* any of them until Stage B (§2 above).
3. **Visual & interaction quality is non-negotiable.** Every screen must feel like a high-end consumer product. Use the `polished-flutter-ui` skill as the source of truth for design tokens, motion, hierarchy, and micro-interactions.
4. **One admin account only.** No signup, no password reset, no multi-user, no roles,
   no user/account-management screen. (This is distinct from the app-level Settings
   tab added after the Stage A review — see `PRD.md` §3.8 — which covers theme,
   version, and support info, not account management. There is still exactly one
   admin account, with no way to change or manage it from within the app.)
5. **No image upload of any kind.** Menu photos are managed by the developer directly in MongoDB + static files. The admin form has zero image-related UI.

---

## 4. Non-negotiable product decisions (already settled — do not relitigate)

1. **Fulfillment types** = only `dine-in` and `pickup`. Never show delivery, address, or delivery fee.
2. **Order statuses** = exactly four: `pending` → `accepted` → `completed`, plus `rejected`. No other states.
3. **Loyalty has two distinct tokens**:
   - `stampToken` → only valid for adding a stamp
   - `redeemToken` → only valid for redeeming, and is rotated after every successful redeem
4. **Scanner never auto-switches mode.** If the scanned token does not match the currently selected mode (Add Stamp / Redeem), show an error and stop.
5. **No phone number anywhere.** Customer cards and order cards show name only.
6. **No image upload, no image picker, no Cloudinary, no photo field in any form.**
7. **Cash only.** No payment UI of any kind.
8. **Distribution** = signed APK sideloaded on the owner’s phone. No Play Store in v1.
9. **Push notifications** use a custom high-importance Android channel with a raw sound asset. A plain FCM notification is not enough when the app is killed.
10. **All business rules live on the server.** The Flutter app may disable buttons for UX, but the server is the final authority (especially status transitions and redeem guards).

---

## 5. Brand identity (must match both apps)

| Token            | Value                          | Usage |
|------------------|--------------------------------|-------|
| Primary ink      | `#3d1a00` (dark brown)         | App bar, active tab, primary text |
| Highlight        | `#facc15` (yellow-400)         | Badges, primary CTAs, accents |
| Card / surface   | `#fff1e3` (cream)              | Cards, elevated surfaces |
| Background       | Soft warm off-white / cream    | Scaffold background |
| Headline font    | Playfair Display (bold/black)  | Screen titles, important numbers |
| Body font        | Inter or equivalent geometric  | Everything else |
| Shape language   | 16–24 px radii, full pills for CTAs | Consistent rounded forms |
| Interaction      | Scale-down on press (0.97–0.98) + light haptic | No Material ripple as primary feedback |

Dark mode is first-class and intentional (deep charcoal, not pure black).  
All colors, radii, spacing, and text styles come from `theme/app_theme.dart` + ThemeExtensions. **Never hard-code `Color(0xFF...)` inside widgets.**

---

## 6. Technical boundaries

- **Platform**: Android only (min SDK as required by the packages we use).
- **State management**: Riverpod only. No `setState` for domain data.
- **Networking**: `dio` + JWT interceptor. 401 → clear token → login screen.
- **Secure storage**: `flutter_secure_storage` for the JWT. Never SharedPreferences for secrets.
- **Scanner**: `mobile_scanner`.
- **Notifications**: `firebase_messaging` + `flutter_local_notifications` (custom channel + sound).
- **Fonts**: `google_fonts` (Playfair Display + Inter / Plus Jakarta Sans equivalent).
- **No** `image_picker`, no upload service, no local database for business data.
- **Local device preferences**: `shared_preferences` — used ONLY for the Settings
  tab's theme choice (added after the Stage A review). This is on-device storage, not
  a backend call, and doesn't violate the Stage A/B split (§2).

API base URL will be injected (dev / production).

> ⚠️ **Current dev environment note:** the backend is currently running locally
> (not deployed) and the Flutter app runs on a physical device, so `localhost` isn't
> reachable from the phone. The dev API base URL currently points at the laptop's
> **Tailscale IP** instead — see `TASKS.md`'s Phase Net for the setup, and its own
> warning that this is **temporary, dev-only**, replaced by the real production URL
> (once the backend is deployed, per the web app's `ARCHITECTURE.md` §8) before
> `Launch-3`. Don't treat any Tailscale IP found in code or config as permanent.

All endpoints are already defined in the backend ARCHITECTURE; the admin app only
consumes them.

---

## 7. How the doc set works

| Document              | Purpose |
|-----------------------|---------|
| **PROJECT_CONTEXT.md** (this file) | Orientation, rules, brand, boundaries |
| **PRD.md**            | What every feature must do from the owner’s point of view |
| **ARCHITECTURE.md**   | Folder structure, models, services, API contracts the app uses, notification & deep-link flows |
| **CODING_STANDARDS.md** | Hard rules for Dart, Riverpod, theming, error handling, testing |
| **TASKS.md**          | Ordered, dependency-aware checklist. One task = one commit. |

**Workflow for any agent or developer**  
1. Read this file.  
2. Open TASKS.md and take the highest unfinished task whose dependencies are done.  
3. Read the sections of PRD + ARCHITECTURE that the task references.  
4. Implement exactly that task.  
5. Tick the box and commit with the task ID.  
Never skip ahead. Never redesign the product.

---

## 8. Design system reference

The visual and interaction language is defined by the **polished-flutter-ui** skill.  
Treat it as law:

- Soft premium surfaces, clear hierarchy, one primary action per screen.
- Thumb-zone primary CTAs.
- Purposeful motion only (spring, 120–450 ms).
- Loading / empty / error states are first-class and friendly.
- Full WCAG AA contrast, ≥ 48 dp touch targets, reduced-motion support.

Every screen must pass the “feels like a high-end product on first launch” test.

---

## 9. What is explicitly out of scope

- Multi-staff / roles / permissions
- Web admin panel
- Image upload or photo management
- Delivery / addresses / phone numbers
- Analytics dashboard
- Kitchen printer
- Customer-facing push notifications
- Play Store release
- Offline-first business data sync
- Any endpoint that does not already exist in the backend contract

If a request would require any of the above, stop and flag it. Do not invent it.

---

**End of PROJECT_CONTEXT.md**
