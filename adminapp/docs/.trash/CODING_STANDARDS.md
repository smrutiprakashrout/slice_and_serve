# CODING_STANDARDS.md — Slice and Serve Admin (Flutter)

Hard rules for the Flutter admin app.  
These exist so that every task produces consistent, maintainable, premium-quality code and so an AI agent has clear constraints instead of free rein.

---

## 0. The rules that matter most

1. **Stage A never calls a real API; Stage B never restyles.** If a task tagged `[A]`
   in `TASKS.md` imports `dio` or touches `core/api_client.dart`, stop — that's a sign
   the task or the stage boundary was misread. If a task tagged `[B]` changes a color,
   radius, font size, or moves a widget, that's scope creep — Stage B is plumbing only,
   matching what Stage A already got approved, pixel for pixel.
3. **Never invent product scope.** If a feature is not in PRD.md or ARCHITECTURE.md, do not build it.
4. **One task = one commit.** Reference the task ID exactly as it appears in `TASKS.md`
   (e.g. `feat(menu): build menu list on mock data (2A-2)` for a Stage A task, or
   `feat(menu): wire menu list to GET /api/menu (2B-1)` for Stage B — see
   `TASKS.md` for the current numbering; don't reuse IDs from an earlier draft).
5. **All colors, radii, spacing, and text styles come from the theme.** No hard-coded `Color(0xFF...)`, no magic numbers for padding or border radius inside widgets.
6. **Riverpod only for domain state, and only once Stage B introduces real async data.**
   No `setState` for menu, orders, loyalty, or auth data once wired for real.
7. **Every async UI handles loading, data, error, and empty.** Use `AsyncValue.when`. A spinner-forever or blank screen on failure is a bug.
8. **Follow the polished-flutter-ui skill** for visual hierarchy, motion, touch targets, and micro-interactions. The skill is the design source of truth.
9. **Server is the source of truth.** Optimistic UI is allowed (and required for availability), but the server response always wins. Revert on failure.
10. **No `dynamic` escapes.** Model every response properly. Treat analyzer warnings as errors.

---

## 1. Dart & project conventions

### Naming
| Thing              | Convention              | Example |
|--------------------|-------------------------|---------|
| Files              | snake_case.dart         | `menu_item_form.dart` |
| Classes            | PascalCase              | `MenuItemForm` |
| Members            | camelCase               | `isAvailable` |
| Private members    | `_` prefix              | `_controller` |
| Constants          | lowerCamel or SCREAMING | `defaultTimeout` / `kMaxStamps` |
| Providers          | camelCase + Provider    | `menuProvider` |
| Enums              | PascalCase              | `OrderStatus.pending` |

### Layering (strict)
```
screens/  →  providers/  →  services/  →  core/api_client.dart
```
- A `Screen` or `Widget` must never import or call `dio` directly.
- A `Service` must never import Flutter widgets or build UI.
- Providers orchestrate services and expose `AsyncValue` or simple state.

### Models
- Every model is immutable (`final` fields).
- Every model has `fromJson` / `toJson` and a `copyWith`.
- Prefer freezed or manual implementation; consistency matters more than the library.
- IDs are `String` once they cross the API boundary.

### Error handling
- Network and business errors are wrapped in a `Result<T>` (or equivalent) at the service layer.
- Never let raw exceptions bubble to the UI.
- Surface the server’s `error.message` when available; fall back to a friendly generic message.
- 401 is handled **once** in the dio interceptor → clear token → navigate to login.

### Logging
- Use a simple logger (or `debugPrint` behind a kDebugMode check).
- Never log tokens, passwords, or full PII.

---

## 2. Riverpod rules

- Use `AsyncNotifier` / `Notifier` (or the equivalent current Riverpod API) for anything that hits the network.
- Expose `AsyncValue<T>` so UI can write:
  ```dart
  ref.watch(menuProvider).when(
    data: (items) => ...,
    loading: () => const SoftLoading(),
    error: (e, st) => ErrorView(onRetry: () => ref.invalidate(menuProvider)),
  );
  ```
- Derived state (e.g. pending count) is computed in a provider, not inside a widget.
- Prefer `ref.invalidate` / `ref.refresh` over manual cache clearing.
- Keep providers focused: one primary responsibility per provider file.

---

## 3. UI & design system rules

### Theme is law
- All colors → `Theme.of(context).colorScheme` or custom `ThemeExtension`s.
- All radii → tokens (cards 20–24, buttons 16–20 or stadium, chips 12–14).
- All spacing → 4 dp grid (8 / 12 / 16 / 20 / 24 / 32 / 48).
- Typography → Playfair for headlines, geometric sans for body (via `google_fonts` or theme).

### Interaction
- Primary buttons: height 52–56 dp, scale to 0.97–0.98 on press, optional light haptic.
- Touch targets ≥ 48 dp.
- One clear primary action per screen, placed in the thumb zone when possible.
- Motion is purposeful only (see polished-flutter-ui skill). Respect `prefers-reduced-motion`.

### States that must exist on every data screen
- Loading (skeleton or soft indicator — never a blank screen)
- Empty (friendly illustration or icon + short message + optional action)
- Error (clear message + retry)
- Offline / network failure (same as error, distinct copy if possible)

### Forms
- Shared `MenuItemForm` for create and edit.
- No image field, no image picker, no upload progress.
- Validate on the client for UX; the server still re-validates.
- Disable the submit button while the request is in flight and show a loading indicator on it.

### Lists & cards
- Consistent card radius and padding.
- Press feedback on interactive cards.
- Availability switch is optimistic with rollback.

---

## 4. Networking

- Single `ApiClient` (dio) instance created in `core/`.
- JWT is attached by an interceptor reading from `SecureStore`.
- Base URL is configurable (dev / prod). Never hard-code production secrets.
- Timeouts are explicit.
- All service methods return `Result<T>` or throw only domain exceptions that the provider catches and turns into `AsyncError`.

### Optimistic updates
- Required for availability toggle.
- Allowed for order status changes if the UX benefit is clear.
- Always roll back and show an error if the server rejects the change.

---

## 5. Security

- JWT lives **only** in `flutter_secure_storage`.
- Never store the admin password.
- Never commit `google-services.json` if project policy forbids it; follow standard FlutterFire practice.
- Strip tokens from any crash-reporting or logging payloads.

---

## 6. Testing requirements (minimum)

**Widget / unit tests that must exist before launch:**
- Login success and failure paths
- Availability toggle (optimistic + rollback)
- Order action buttons (Accept / Reject / Complete) and the Reject confirmation
- Mode mismatch on loyalty scan (stamp QR in Redeem mode and vice-versa)

**Manual device tests (mandatory):**
- FCM when app is killed, screen off, and under battery optimization
- Deep link from notification → Orders tab → Pending filter
- Camera permission flows and scanner on a real device

Emulators are not sufficient for notification or camera verification.

---

## 7. Git & commit rules

- Branch: `feat/<task-id>-short-name` (e.g. `feat/2B-2-menu-availability`)
- Commit message follows Conventional Commits and includes the exact task ID from
  `TASKS.md` — note the `A`/`B` stage suffix is part of the ID, not decoration:
  ```
  feat(menu): build menu list screen on mock data (2A-2)
  feat(menu): wire optimistic availability toggle with rollback (2B-2)
  fix(loyalty): block mode mismatch on scan (3B-2)
  chore(theme): add cream surface token (0-2)
  ```
- Run `flutter analyze` and the relevant tests before committing.
- Never commit secrets, keystores, or `google-services.json` with private keys.

---

## 8. Documentation upkeep

- New screen or major flow → update ARCHITECTURE.md in the same commit if the structure changed.
- Finished task → tick it in TASKS.md in the same commit.
- Any deviation from a settled decision in PROJECT_CONTEXT.md or PRD.md must be explicitly approved and documented; do not silently change product rules.

---

## 9. What “done” means for any screen

- [ ] Uses only theme tokens (no hard-coded colors/radii)
- [ ] Has loading / empty / error states
- [ ] Primary action is obvious and in thumb zone
- [ ] Press feedback + optional haptic on interactive elements
- [ ] Works in light and dark mode
- [ ] Survives rapid tab switching and pull-to-refresh
- [ ] 401 anywhere returns the user to login
- [ ] Feels calm, premium, and trustworthy (polished-flutter-ui bar)

---

**End of CODING_STANDARDS.md**
