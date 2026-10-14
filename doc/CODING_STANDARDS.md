# CODING_STANDARDS.md — Slice and Serve

Rules for both codebases. These exist so that a task done today doesn't create work
tomorrow, and so an AI agent has hard constraints instead of free rein.

---

## 0. The rules that matter most

1. **Do not redesign the UI.** The customer app's visual work is finished and approved.
   Backend tasks change *where data comes from*, never how it looks. If a task makes you
   want to restructure JSX, you've misread the task.
2. **Never delete a `// TODO` comment without doing the TODO.** Several files
   (`mock-user-data.ts`, `profile/page.tsx`) carry deliberate TODOs marking the
   mock→real swap points. They are the map.
3. **One task, one commit.** Never bundle. A commit that touches the menu API and the
   loyalty UI is not reviewable.
4. **`npm run build` must pass before every commit.** Not `npm run dev` — the full
   type-checked build.
5. **No `any`.** Not in TypeScript, not as `dynamic` everywhere in Dart. If you reach
   for it, model the type properly.

---

## 1. TypeScript / Next.js

### Types
- `strict` stays on. No `any`, no `@ts-ignore`. `@ts-expect-error` is allowed only with
  a comment explaining why and when it can be removed.
- Shared types live next to their source of truth: DB types in `model/`, API response
  types in `lib/types.ts`. Components import them; they never redefine them locally.
- Prefer `interface` for object shapes, `type` for unions and utilities.
- Never widen an ID to `string` when it's a Mongo `ObjectId` — convert explicitly at the
  API boundary and type it as `string` from there on.

### File & naming conventions
| Thing | Convention | Example |
|---|---|---|
| Route files | Next.js reserved names | `app/api/menu/route.ts` |
| Components | PascalCase file + default export | `app/components/BottomNav.tsx` |
| Hooks | `use` prefix, camelCase file | `lib/useScrollDirection.ts` |
| Libs/helpers | kebab-case | `lib/cart-store.ts`, `lib/admin-auth.ts` |
| Mongoose models | PascalCase singular | `model/MenuItem.ts` |
| Constants | `SCREAMING_SNAKE` | `CATEGORIES`, `DEFAULT_STAMP_TARGET` |
| Booleans | `is`/`has`/`can` prefix | `isLoading`, `hasRewardReady` |

- Route groups `(customer)` and `(standalone)` are meaningful: `(customer)` pages get
  the bottom nav, `(standalone)` don't. Put a new page in the right group.
- Server Components by default. Add `"use client"` only when you actually need state,
  effects, or browser APIs — and put it on the smallest component that needs it, not
  the whole page, where practical.

### API routes
Every route follows the same skeleton:

```ts
import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";
import { requireAdmin } from "@/lib/admin-auth";   // admin routes only
import { auth } from "@/auth";                      // customer routes only

export async function POST(request: Request) {
  try {
    await connectDB();
    const admin = await requireAdmin(request);      // throws ApiError(401)
    const body = await request.json();
    // 1. validate input  2. enforce business rules  3. write Mongo
    // 4. (no Firestore mirror — see ARCHITECTURE.md §5.8)  5. respond
    return NextResponse.json(result, { status: 201 });
  } catch (err) {
    return handleApiError(err);                     // from lib/api-error.ts
  }
}
```

- **Always `await connectDB()` first.** It must be idempotent and cached.
- **Validate every input at the boundary.** Never trust a client-supplied price, total,
  status, or customer ID.
- **Never `export const runtime = "edge"`** on a route that touches Mongo.
- Use a single `handleApiError` so every error response has the same
  `{ error: { code, message } }` shape. Never leak stack traces or Mongo errors to the
  client; log them server-side instead.
- Business-rule guards live in the API, never in the client. The Flutter app disabling a
  button is UX; the server rejecting the transition is the actual rule.

### Data fetching in the customer app
- Client-side reads use **SWR** (already a dependency). One `useSWR` call per resource,
  with a shared fetcher in `lib/fetcher.ts`.
- Every fetch renders three states: loading, error, empty. A spinner-forever on failure
  is a bug.
- Mutations use optimistic updates with rollback via SWR's `mutate`, matching how the
  cart already behaves.
- Real-time-ish updates use SWR's `refreshInterval` (polling), not Firestore listeners —
  see `ARCHITECTURE.md` §5.8. Pause polling when the tab isn't visible; don't poll a
  page that isn't mounted.

### Styling
- Tailwind v4 utilities only. No CSS modules, no styled-components, no inline `style`
  except for genuinely dynamic values (computed transforms, animation offsets).
- Use the brand tokens from `PROJECT_CONTEXT.md` §5. Don't introduce a new brown.
- GSAP animations: always kill timelines on unmount. There is prior art in the repo (see
  the `gsap` usage in `cart/page.tsx`) — follow it.

### Secrets
- Server-only env vars are read **only** in server files. Anything prefixed
  `NEXT_PUBLIC_` is public — the Firebase *web* keys are fine there; the Firebase
  *admin* key, Mongo URI, and JWT secrets never are.
- No secret is ever hardcoded, logged, or committed. `.env.example` holds keys with
  empty values and is committed; `.env.local` holds values and is not.

---

## 2. Dart / Flutter

- Enable `flutter_lints`; treat analyzer warnings as errors in CI.
- Files `snake_case.dart`; classes `PascalCase`; members `camelCase`; private members
  prefixed `_`.
- **State management is Riverpod.** No `setState` for anything beyond purely local
  widget UI (an expanded/collapsed flag is fine; order data is not).
- **Layering is strict:** `screens/` → `providers/` → `services/` → `api_client`.
  A widget must never call `dio` directly, and a service must never build a widget.
- Every model gets `fromJson` / `toJson` and is immutable (`final` fields, `copyWith`).
- Network results are wrapped in a `Result<T>` (success/failure) — no throwing across
  layers, no bare `catch (e) {}`.
- Every async screen handles loading, error, and empty explicitly. Riverpod's
  `AsyncValue.when` makes this the default; use it.
- Colors, radii, and text styles come from `theme/app_theme.dart`. **No hardcoded
  `Color(0xFF...)` in a widget file.**
- `const` constructors wherever possible.
- Handle `401` centrally in the dio interceptor, never per-screen.

---

## 3. Git

**Branches:** `main` is deployable. Work on `feat/<task-id>-short-name`, e.g.
`feat/P3-4-menu-admin-crud`.

**Commits** follow Conventional Commits and reference the task ID:

```
feat(menu): serve GET /api/menu from MongoDB (P3-2)
fix(profile): remove undefined totalOrders destructure (P0-1)
chore(repo): delete empty app/admin and app/kitchen (P0-3)
docs(arch): document loyalty token rotation
refactor(orders): collapse status enum to 4 states (P5-1)
```

Types: `feat` `fix` `chore` `docs` `refactor` `test` `style`.

**Before every commit:** `npm run lint && npm run build` (or
`flutter analyze && flutter test`). No `--no-verify`.

**Never commit:** `.env.local`, `google-services.json`, keystore files, service account
JSON, `node_modules`, `tsconfig.tsbuildinfo` (currently tracked — untrack it).

---

## 4. Testing

Full test coverage is not the v1 goal. These specific things **must** be tested because
they're where silent, expensive bugs live:

**Backend (Vitest):**
- Order status transition guards — especially that `pending → completed` is rejected.
- Server-side total recomputation ignores a client-supplied total.
- Stamp increment flips `rewardReady` exactly at `totalRequired`, and never exceeds it.
- Redeem rotates `redeemToken` and the old token then resolves to nothing.
- A `stampToken` scanned in redeem mode returns `action: "stamp"` and cannot redeem.
- Every admin route returns 401 without a valid admin JWT.
- A customer session token cannot authenticate an admin route.

**Flutter:** widget tests for login, the availability toggle, and the order action
buttons. QR scanning and FCM-with-app-killed are **manual device tests** — emulators
lie about both.

**Manual QA:** the 8-step script in `PRD.md` §6 is the release gate. Run it end-to-end
on a real phone before shipping an APK.

---

## 5. Documentation upkeep

- New endpoint → add a row to `ARCHITECTURE.md` §4 in the same commit.
- New env var → add it to `.env.example` and `PROJECT_CONTEXT.md` §6 in the same commit.
- Finished task → tick it in `TASKS.md` in the same commit.
- Changed a settled decision → update `PROJECT_CONTEXT.md` §4 and note why. A decision
  that lives only in chat history does not exist.
