# Sprint 3 — GPS Tracking Module

**Duration**: 2 weeks · **Goal**: implement continuous device location tracking.

## Deliverables

| Deliverable                 | Where                                                          |
| --------------------------- | -------------------------------------------------------------- |
| Real-time location tracking | `mobile/lib/features/tracking/` + `LocationsModule` backend  |
| Offline location buffer     | SQLite `pending_locations` in `anti_leba.db`                   |
| Location API                | `POST /api/locations`, `POST /api/locations/batch`, `GET /api/locations` |

## Acceptance criteria

- [x] Device location collected every **5 minutes** (`TrackingConfig.interval`, Geolocator `intervalDuration`)
- [x] Locations stored successfully (Prisma `locations` table + device ownership validation)
- [x] Offline storage works correctly (SQLite queue → batch sync when online)

## Backend

### `locations` table

| Column       | Type        | Notes                          |
| ------------ | ----------- | ------------------------------ |
| id           | UUID        | PK                             |
| device_id    | UUID        | FK → devices, CASCADE          |
| latitude     | float       | −90 … 90                       |
| longitude    | float       | −180 … 180                     |
| accuracy     | float?      | metres                         |
| altitude     | float?      | metres                         |
| speed        | float?      | m/s                            |
| heading      | float?      | 0 … 360°                       |
| recorded_at  | timestamptz | client capture time            |
| created_at   | timestamptz | server insert time             |

### API

| Method | Path                   | Description                         |
| ------ | ---------------------- | ----------------------------------- |
| POST   | `/api/locations`       | Store one fix (validates coords)    |
| POST   | `/api/locations/batch` | Store up to 100 fixes (offline sync)|
| GET    | `/api/locations?deviceId=` | List recent fixes for owned device |

Coordinates validated via `class-validator` (`@Min/@Max` on lat/lng). Writes call `DevicesService.touchLastSeen()`.

## Mobile

### Packages added

`geolocator`, `permission_handler`, `sqflite`, `path`, `path_provider`, `connectivity_plus`

### Flow

1. User reaches dashboard with enrolled device → tracking auto-starts
2. Runtime permissions requested (foreground + background location)
3. Android foreground service notification shown while tracking
4. Every **5 min**: GPS sample → save to SQLite → upload to server
5. Upload failure → row stays in `pending_locations`; **Sync** button + 1-min background retry
6. Logout stops tracking stream and clears state

### Dashboard

- **Tracking** card shows active/idle, last coordinates, last sample time
- **Offline buffer** card shows unsynced count + manual **Sync**

## Migration

```bash
cd backend
npx prisma migrate deploy   # applies 20260615120000_add_locations
```

## Test

```bash
# Upload a fix
curl -X POST http://localhost:3000/api/locations \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"<uuid>","latitude":9.03,"longitude":38.74,"accuracy":12.5,"recordedAt":"2026-06-15T10:00:00.000Z"}'

# List recent
curl "http://localhost:3000/api/locations?deviceId=<uuid>&limit=10" \
  -H "Authorization: Bearer <token>"
```
