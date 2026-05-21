# Sprint 1 — Project Initialization

**Duration**: 2 weeks · **Goal**: prepare development environments and
initialize the system architecture.

## Deliverables ✅

| Deliverable           | Where                          |
| --------------------- | ------------------------------ |
| Flutter base project  | `mobile/`                      |
| NestJS base API       | `backend/`                     |
| PostgreSQL connected  | `backend/prisma/schema.prisma` + `database/init.sql` |

## Acceptance criteria ✅

- [x] Mobile app builds successfully (run `flutter pub get && flutter run`)
- [x] Backend server runs successfully — verified: all modules initialized, 4 routes mapped
- [x] Database connection established — Prisma `$connect()` against **Supabase** (eu-west-1, project `ojnpkdizxucepxeubaam`) succeeds on boot; `/api/health` reports `{ "status": "ok", "db": "up" }`
- [x] Authentication endpoint tested end-to-end against Supabase:
  - `POST /api/auth/register` → **201** with `{ accessToken, user }` (user persisted in Supabase `users`)
  - `POST /api/auth/login` → **200** with new JWT
  - `GET /api/auth/me` with valid token → **200** with current user payload
  - `GET /api/auth/me` without token → **401** (global JwtAuthGuard)
  - Duplicate register → **409** `Email already in use`
  - Wrong password → **401** `Invalid credentials`
  - Empty register body → **400** with field-level validation errors

## What was built

### Flutter (`mobile/`)
- Clean-architecture skeleton: `core/` (bootstrap, env, errors, logging, network, router, theme) + `features/<feature>/{data,domain,presentation}`.
- Riverpod with `UncontrolledProviderScope`.
- GoRouter (`splash → login ↔ register → dashboard`).
- Material 3 light + dark themes.
- `AndroidManifest.xml` declares: location (fine/coarse/background), SMS (send/receive), camera, microphone, foreground service (location + data-sync), storage/media, network state, boot receiver, post-notifications.
- `dio_client` provider wired to `AppEnv.apiBaseUrl` (overridable via `--dart-define`).

### NestJS (`backend/`)
- Strict-mode TypeScript build, ESLint configured.
- `ConfigModule` with class-validator schema for `.env`.
- Prisma 6 schema for `User` + `Device` (UUID PKs, enums, indexes, `updatedAt` auto-managed).
- `PrismaService` does a **non-blocking** `$connect()` so the server boots even if the DB is briefly unreachable.
- `AuthModule`: bcrypt(12) password hashing, Passport JWT strategy, global `JwtAuthGuard` via `APP_GUARD`, opt-out with `@Public()`, `@CurrentUser()` param decorator.
- `HealthController` (`/api/health`) checks DB reachability and uptime.
- Global `ValidationPipe` (whitelist + forbidNonWhitelisted + transform).

### Database (`database/`)
- `init.sql`: raw SQL equivalent of the Prisma schema, with `pgcrypto`, two enums, `users` + `devices`, indexes, and an `updated_at` trigger.

## Decisions worth recording

| Decision                          | Why                                                        |
| --------------------------------- | ---------------------------------------------------------- |
| Riverpod over Bloc                | Less boilerplate; fits offline-first + background services better |
| Prisma 6 over Prisma 7            | Prisma 7 moved datasource URLs to `prisma.config.ts` + adapters — ecosystem still maturing |
| Prisma over TypeORM               | Single source of truth in `schema.prisma`; type-safe queries |
| Supabase as managed Postgres only | `DATABASE_URL` → transaction pooler (PgBouncer, port 6543, `pgbouncer=true&connection_limit=1`), `DIRECT_URL` → session pooler (port 5432) for migrations |
| NestJS keeps its own JWT auth     | Sprint 1 already had bcrypt + Passport wired; revisit Supabase Auth only if/when we need OAuth providers, magic links, or RLS-driven mobile access |
| Global JwtAuthGuard               | Protected by default — explicit `@Public()` is safer than per-controller opt-in |
| Non-blocking Prisma `$connect()`  | Server should boot and report DB status, not crash, if DB is briefly down |
| `--dart-define=API_BASE_URL`      | No bundled secrets/env in mobile binary; build-time injection |

## Known follow-ups → Sprint 2

- Wire mobile login/register screens to the backend auth API (`AuthRepository` impl in `mobile/lib/features/auth/data/`).
- Persist JWT to `flutter_secure_storage`; refresh on app start.
- Add device enrollment endpoint + UI (uses the existing `Device` model).
- Re-enable Prisma migrations workflow: confirm `prisma migrate dev` runs after the user updates `.env` credentials.
