# Sprint 2 — Authentication & Device Registration

**Duration**: 2 weeks · **Goal**: implement secure user authentication and device registration.

## Deliverables

| Deliverable                    | Where                                                                 |
| ------------------------------ | --------------------------------------------------------------------- |
| User authentication system     | `backend/src/modules/auth/` + `mobile/lib/features/auth/`             |
| Device registration workflow   | `backend/src/modules/devices/` + `mobile/lib/features/devices/`       |
| Server-side sessions           | `backend/prisma/schema.prisma` → `Session` model                      |

## Acceptance criteria

- [x] User can register (`POST /api/auth/register` + mobile Register screen)
- [x] User can login (`POST /api/auth/login` + mobile Login screen)
- [x] Device registers successfully (`POST /api/devices/register` after auth)
- [x] JWT authentication works (Bearer token + `sid` session validation + logout revokes session)

## Backend

### New: `sessions` table

Tracks active JWT sessions server-side. Each login/register creates a row; logout sets `revoked_at`. JWT payload includes `sid`; `JwtStrategy` rejects revoked/expired sessions.

### Auth updates

| Endpoint              | Change                                      |
| --------------------- | ------------------------------------------- |
| `POST /api/auth/register` | Creates session + JWT with `sid`        |
| `POST /api/auth/login`    | Creates session + JWT with `sid`        |
| `GET /api/auth/me`        | Returns `{ id, email, role, sessionId }` |
| `POST /api/auth/logout`     | **New** — revokes session (204)           |

### Device registration API

| Method | Path                     | Auth   | Description                              |
| ------ | ------------------------ | ------ | ---------------------------------------- |
| POST   | `/api/devices/register`  | Bearer | Enroll/update current device for user    |
| GET    | `/api/devices`           | Bearer | List user's devices                      |
| GET    | `/api/devices/:id`       | Bearer | Get one device owned by user             |

Upsert by `deviceUid`: same user → update metadata; different user → 409.

## Mobile

### Auth data layer

- `AuthRemoteDataSource` → `/auth/register`, `/auth/login`, `/auth/logout`
- `AuthLocalDataSource` → `SessionStorage` via `flutter_secure_storage`
- `AuthRepositoryImpl` → coordinates remote + local
- `AuthController` (Riverpod) → restore session on boot, login/register/logout

### Token storage

JWT persisted in secure storage as JSON (`auth_session` key). In-memory `accessTokenProvider` feeds Dio `Authorization: Bearer …` interceptor.

### Device information collection

`DeviceInfoService` collects:

- `deviceUid` — Android ID (fallback UUID in secure storage)
- `manufacturer`, `model`, `osVersion` — from `device_info_plus`
- `appVersion` — from `package_info_plus`

Auto-enrolled after successful login or register.

### Router guards

`GoRouter` redirect: unauthenticated users → `/login`; authenticated users on auth screens → `/dashboard`. Splash restores session then routes accordingly.

## Run / test

```bash
# Backend
cd backend
npx prisma migrate dev --name add_sessions
npm run start:dev

# Mobile (USB device with adb reverse)
adb reverse tcp:3000 tcp:3000
cd mobile
flutter pub get
flutter run -d <device-id> --dart-define=API_BASE_URL=http://localhost:3000
```

### Smoke test (curl)

```bash
# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"fullName":"Test User","email":"test2@example.com","password":"changeme1!"}'

# Login → copy accessToken
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test2@example.com","password":"changeme1!"}'

# Register device
curl -X POST http://localhost:3000/api/devices/register \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"deviceUid":"android-test-001","label":"Galaxy M33","manufacturer":"Samsung","model":"SM-M336BU","osVersion":"Android 16","appVersion":"0.1.0"}'

# Logout (token invalidated)
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Authorization: Bearer <token>"
```

## Migration note

Run `npx prisma migrate dev --name add_sessions` against Supabase to create the `sessions` table before testing logout/session validation.
