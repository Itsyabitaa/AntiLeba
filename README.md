# Anti-Leba — Smart Anti-Theft Recovery System

> Sprint 1: project initialization. Mobile (Flutter) + Backend (NestJS) +
> Database (PostgreSQL), set up as a monorepo.

## Repository layout

```
.
├── backend/    # NestJS API + Prisma ORM
├── mobile/     # Flutter mobile client (Riverpod + GoRouter + Dio)
├── database/   # init.sql + DB notes
├── docs/       # (future) architecture diagrams, sprint notes
├── .editorconfig
├── .gitignore
└── README.md
```

## Tech stack

| Layer    | Choice                                                   |
| -------- | -------------------------------------------------------- |
| Mobile   | Flutter 3.22+ · Riverpod · GoRouter · Dio                |
| Backend  | NestJS 11 · TypeScript strict · Passport JWT             |
| ORM      | Prisma 6 (PostgreSQL provider)                           |
| Database | PostgreSQL 14+                                           |

## Sprint 1 status

### Flutter tasks
- [x] Create Flutter project
- [x] Configure Android permissions (location/SMS/camera/foreground service)
- [x] Setup clean architecture (`core/` + `features/<feature>/{data,domain,presentation}`)
- [x] Setup Riverpod state management
- [x] Configure app themes (Material 3 light + dark) and navigation (GoRouter)

### NestJS tasks
- [x] Create NestJS project
- [x] Setup PostgreSQL connection (via Prisma, non-blocking)
- [x] Configure environment variables (validated `ConfigModule`)
- [x] Setup JWT authentication (register / login / me, global `JwtAuthGuard`, `@Public()` opt-out)
- [x] Setup project modules (`Auth`, `Users`, `Devices`, `Prisma`, `Health`)

### Database tasks
- [x] Create initial tables: `users`, `devices` (Prisma schema + raw SQL)

### Deliverables
- [x] Flutter base project (`mobile/`)
- [x] NestJS base API (`backend/`)
- [x] PostgreSQL connected (via Prisma)

### Acceptance criteria
- [x] **Mobile app builds** — `flutter pub get` then `flutter run`
- [x] **Backend server runs** — `npm run start:dev` → boots, all modules load, routes mapped
- [x] **Database connection established** — Prisma connects to Postgres on startup, `/api/health` reports `db` status
- [x] **Authentication endpoint tested** — `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me`; global JWT guard verified to return 401 without a token; validation pipe verified to return 400 on bad payloads

## Prerequisites

| Tool       | Version |
| ---------- | ------- |
| Node.js    | ≥ 20    |
| Flutter    | ≥ 3.22  |
| PostgreSQL | ≥ 14    |
| Android Studio / Xcode | for emulators |

## Quick start

### 1. Database

```bash
createdb anti_leba   # or use your existing Postgres database
```

Update `backend/.env` with your credentials:

```env
DATABASE_URL=postgresql://USER:PASS@localhost:5432/anti_leba?schema=public
JWT_SECRET=<a long random string>
```

### 2. Backend

```bash
cd backend
npm install
npx prisma migrate dev --name init   # creates users + devices tables
npm run start:dev                    # http://localhost:3000/api
```

Smoke tests:

```bash
curl http://localhost:3000/api/health

curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"fullName":"Test User","email":"test@example.com","password":"changeme1!"}'

curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"changeme1!"}'

# Use the accessToken from login in subsequent calls:
curl http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer <accessToken>"
```

### 3. Mobile

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   # Android emulator
```

> Real device? Use your machine's LAN IP (`ipconfig` / `ifconfig`):
> `--dart-define=API_BASE_URL=http://192.168.1.50:3000`

## API surface (Sprint 1)

| Method | Path                  | Auth     | Description                  |
| ------ | --------------------- | -------- | ---------------------------- |
| GET    | `/api/health`         | public   | Liveness + DB reachability   |
| POST   | `/api/auth/register`  | public   | Create a new owner account   |
| POST   | `/api/auth/login`     | public   | Exchange creds for JWT       |
| GET    | `/api/auth/me`        | Bearer   | Current authenticated user   |

All routes are protected by a global `JwtAuthGuard`; public routes opt out
with `@Public()`.

## Project decisions

- **Monorepo**: keeps mobile, backend, and DB schema in lockstep for the
  duration of the project. Each folder has its own `README.md` with details.
- **Riverpod** (over Bloc): less boilerplate, better-suited for the
  background-services + offline-first use cases we'll need from Sprint 2 on.
- **Prisma 6** (over TypeORM): type-safe, single source of truth in
  `prisma/schema.prisma`. Prisma 7 introduced a `prisma.config.ts` adapter
  model that's still maturing — we'll re-evaluate in a later sprint.
- **Global `JwtAuthGuard`**: protected-by-default; explicit `@Public()` is
  safer than relying on each controller to remember `@UseGuards`.

## Roadmap

| Sprint | Focus                                                         |
| ------ | ------------------------------------------------------------- |
| 1      | **(this one)** project initialization                         |
| 2      | Auth UI wiring on mobile + device enrollment                  |
| 3      | GPS tracking + foreground service                             |
| 4      | Offline buffer + sync                                         |
| 5      | SIM-change detection + SMS fallback                           |
| 6      | Camera capture (evidence)                                     |
| 7+     | Remote commands, alerts, admin dashboard, hardening           |
