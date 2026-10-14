# DEFINITION_OF_DONE.md — Slice and Serve Admin (Flutter)

> Referenced by `AGENTS.md` step 7 — run through this before finishing **any** task,
> not just at the end of a phase. If you (the person running this project) have your
> own preferences here, edit this file directly; what follows is a reasonable default
> synthesized from `CODING_STANDARDS.md` §9 and the polished-flutter-ui skill §7,
> split by stage since an `[A]` task and a `[B]` task have different finish lines.

---

## Before marking ANY task done

- [ ] `flutter analyze` is clean — zero warnings, not just zero errors.
- [ ] The task's own acceptance check (from `TASKS.md`'s task description) actually
      passed — not just "the code compiles."
- [ ] The commit message references the exact task ID as it appears in `TASKS.md`
      (see `CODING_STANDARDS.md` §7 for the format).
- [ ] Nothing outside this task's stated scope was touched. If you found yourself
      editing a file the task didn't mention, stop and reconsider before committing.

---

## Additionally, for a Stage `[A]` task (UI on mock data)

- [ ] Zero `dio` calls, zero real networking — confirm by checking the diff doesn't
      touch `core/` or `services/`.
- [ ] Uses only theme tokens from `theme/app_theme.dart` / `DESIGN_TOKENS.md` — no
      hard-coded `Color(0xFF...)`, no magic padding/radius numbers.
- [ ] Works correctly in **both** light and dark mode — actually toggle the device/
      emulator theme and look, don't assume.
- [ ] Has loading / empty / error states designed and reachable via a mock trigger,
      wherever the screen will eventually need them in Stage B.
- [ ] Primary action is obvious and sits in the thumb zone.
- [ ] Every interactive element gives press feedback (scale + optional haptic).
- [ ] Passes the polished-flutter-ui skill's §7 checklist — read it again for this
      specific screen, don't rely on memory.
- [ ] **You've actually looked at it** on a device or emulator and it feels right —
      not just "matches the spec on paper."

## Additionally, for a Stage `[B]` task (real wiring)

- [ ] Visually **identical** to what Stage A already had approved — if anything looks
      different, that's a bug in this task, not an improvement.
- [ ] Matches the exact request/response shape in `ARCHITECTURE.md` §4 — field names,
      status codes, error envelope.
- [ ] Handles all three async states for real: loading, error (with retry), and
      genuinely empty data — not just the happy path.
- [ ] A `401` anywhere correctly clears the token and returns to login (verify this
      specific task doesn't have its own competing error-handling that bypasses the
      central interceptor).
- [ ] Optimistic updates (where specified) roll back cleanly on a failed request —
      actually test the failure path, e.g. by temporarily pointing the API base URL
      somewhere invalid.
- [ ] No secrets, tokens, or PII appear in any log statement.

## Additionally, for a `[Push]` task

- [ ] Tested on a **real device**, not just an emulator.
- [ ] Specifically tested with the app fully killed (swiped away), not just
      backgrounded.
- [ ] Tested with the screen off.
- [ ] If it fails under battery optimization on the test device, that's documented
      (which OEM setting the owner needs to change) rather than silently accepted.

## Additionally, for `Launch` tasks

- [ ] The full acceptance script in `PRD.md` §5 was run start to finish, on a real
      device, against the real (not local-dev) backend.
- [ ] No debug logging, no test credentials, no hardcoded dev API URLs remain in the
      release build.
- [ ] The keystore used for the release build is backed up somewhere safe — losing it
      means every future update requires a fresh app install for the owner.
