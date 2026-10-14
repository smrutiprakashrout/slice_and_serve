# AGENTS.md — Slice and Serve Admin (Flutter)

You are an expert Flutter engineer working **only** on the admin Android app.

## Project location (very important)

The overall repository root is a Next.js application (customer web app + API).

The Flutter admin app lives inside:

```
adminapp/
```

**All of your work happens inside `adminapp/`.**

Inside `adminapp/` you will find:

```
adminapp/
├── docs/                  ← PROJECT_CONTEXT.md, PRD.md, ARCHITECTURE.md, CODING_STANDARDS.md, TASKS.md
├── skills/                ← polished-flutter-ui skill
├── AGENTS.md              ← this file
├── DESIGN_TOKENS.md
├── DEFINITION_OF_DONE.md
└── lib/ ...
```

### Mandatory reading order (every task)

1. Read this file (`adminapp/AGENTS.md`)
2. Read `adminapp/docs/PROJECT_CONTEXT.md`
3. Read the specific task from `adminapp/docs/TASKS.md`
4. Read the relevant sections of:
   - `adminapp/docs/ARCHITECTURE.md`
   - `adminapp/docs/PRD.md`
   - `adminapp/docs/CODING_STANDARDS.md`
5. Apply the skill in `adminapp/skills/polished-flutter-ui/`
6. Use `adminapp/DESIGN_TOKENS.md` for all colors, radii, and spacing
7. Before finishing, run through `adminapp/DEFINITION_OF_DONE.md`

Never look for documentation outside the `adminapp/` folder.  
Ignore the root-level `doc/` folder and root-level `AGENTS.md` — those belong to the Next.js app.

---

## Hard rules

- **The build is Stage A (mock data, zero API calls) then Stage B (real wiring) — see
  `PROJECT_CONTEXT.md` §2.** Every task in `TASKS.md` is tagged `[A]` or `[B]`. Every
  `[A]` task across every phase is done and approved before any `[B]` task starts —
  this is a hard gate, not per-phase.
- You are building **only** the Flutter admin app inside `adminapp/`.
- Never invent features. Never change settled product decisions.
- One task = one commit. Always reference the task ID.
- No hard-coded colors, radii, or magic spacing values.
- All visual decisions must come from `DESIGN_TOKENS.md` + the polished-flutter-ui skill.
- Riverpod only for domain state. No `setState` for menu / orders / loyalty / auth data.
- Every async screen must handle loading, empty, and error states.
- Server is the single source of truth. Optimistic UI is allowed but must roll back on failure.
- No image upload, no phone numbers, no delivery, no extra screens, no multi-user features.
- 401 from any API call must clear the token and return to the login screen.

If a user request conflicts with the documents inside `adminapp/docs/`, stop and say so clearly. Do not implement it.

---

## Working style

- Prefer small, focused changes that match the current task exactly.
- Keep the UI calm, premium, and consistent with the polished-flutter-ui skill.
- When in doubt, re-read the relevant section of the docs inside `adminapp/docs/` instead of guessing.
