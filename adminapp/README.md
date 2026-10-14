# Slice and Serve Admin (Flutter)

Internal Android app for Slice & Serve shop management (menu, orders, loyalty, settings).

---

## Local Development & Networking (Phase Net)

> ⚠️ **TEMPORARY DEV-ONLY CONFIGURATION**
> The backend Next.js API is currently running locally on the development laptop and accessed from the physical test device over Tailscale.
> This value is **strictly temporary** and must be swapped for the production API URL before `Launch-3`.
> See `docs/PROJECT_CONTEXT.md` §6, `docs/ARCHITECTURE.md` §9, and `docs/TASKS.md` Phase Net.

- **Dev Server Port:** `3000`
- **Laptop Tailscale IP:** `100.112.216.27`
- **Dev API Base URL:** `http://100.112.216.27:3000`
- **Health Check Endpoint:** `http://100.112.216.27:3000/api/health`

### Constants Block for Task 1B-1 (`lib/core/constants.dart`):

```dart
// DEV ONLY — Tailscale IP, replace with production URL before
// Launch-3. See PROJECT_CONTEXT.md §6 and ARCHITECTURE.md §9.
const String kDevApiBaseUrl = 'http://100.112.216.27:3000';
```
