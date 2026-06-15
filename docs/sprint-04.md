# Sprint 4 — Offline Storage & Synchronization

**Duration**: 2 weeks · **Goal**: enable offline-first functionality.

## Deliverables

| Deliverable                    | Where                                              |
| ------------------------------ | -------------------------------------------------- |
| Offline synchronization system | Hive queue + `LocationSyncEngine` + batch API dedup |

## Acceptance criteria

- [x] Offline locations stored locally (Hive `pending_locations` box)
- [x] Data automatically syncs when internet returns (`connectivity_plus` listener)
- [x] No duplicate uploads (`clientEventId` unique per device on server + Hive key)

## Mobile changes (Sprint 3 → 4)

| Before (Sprint 3)        | After (Sprint 4)                                      |
| ------------------------ | ----------------------------------------------------- |
| SQLite `pending_locations` | **Hive** `pending_locations` box                    |
| 1-min sync timer in GPS service | Dedicated **`LocationSyncEngine`**          |
| Manual sync only on failure retry | Auto-sync on connectivity + 2-min retry with backoff |
| No client event IDs      | UUID **`clientEventId`** on every fix                 |

### Hive queue

Each unsynced GPS fix is stored as a map keyed by `clientEventId`:

- `deviceId`, lat/lng, accuracy, altitude, speed, heading, `recordedAt`
- `retryCount`, `lastAttemptAt` (updated on failed upload)

### LocationSyncEngine

- Listens to `Connectivity().onConnectivityChanged`
- Runs periodic retry every **2 minutes**
- Up to **3 attempts** with exponential backoff (2s, 4s, 6s)
- Removes queue entries after successful batch upload (including server-reported duplicates)

## Backend changes

### `client_event_id` column

Added to `locations` with unique constraint on `(device_id, client_event_id)`.

### Batch API response (updated)

`POST /api/locations/batch` now returns:

```json
{
  "inserted": 3,
  "skipped": 1,
  "locations": [ ... ]
}
```

- **inserted** — new rows written
- **skipped** — duplicates (same `clientEventId` for device) ignored idempotently

Single `POST /api/locations` also deduplicates when `clientEventId` is supplied.

## Migration

```bash
cd backend
npx prisma migrate deploy   # applies 20260615140000_add_location_client_event_id
```

## Test offline sync

1. Start app, login, reach dashboard (tracking + sync engine start)
2. Enable airplane mode on phone
3. Wait for GPS samples (or force by restarting tracking) — dashboard shows unsynced count rising
4. Disable airplane mode — sync engine uploads batch automatically; count drops to 0
5. Re-trigger sync — server returns `skipped` not duplicate rows (check Supabase `locations` table row count)

## Architecture

```
GPS sample
   ↓
saveLocally() → Hive box (key = clientEventId)
   ↓
LocationSyncEngine.syncWithRetry()
   ↓
POST /api/locations/batch  →  dedupe by (deviceId, clientEventId)
   ↓
markSynced() → delete from Hive
```
