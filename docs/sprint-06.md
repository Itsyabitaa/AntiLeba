# Sprint 6 — SIM Card Change Detection

**Duration**: 2 weeks · **Goal**: detect SIM replacement and activate theft protection.

## Deliverables

| Deliverable | Where |
| ----------- | ----- |
| SIM monitoring system | `features/sim/` + Android `SIM_STATE_CHANGED` EventChannel |
| SIM change logging API | `backend/src/modules/sim-changes/` |
| Database table | `sim_changes` (Prisma + `database/init.sql`) |

## Acceptance criteria

- [x] SIM change detected immediately (native broadcast + 15s poll fallback)
- [x] Alert sent successfully (`ANTI-LEBA THEFT ALERT` SMS)
- [x] Event stored in database (`POST /api/sim-changes`)
- [x] Device status set to `LOST` on report

## Flutter changes

| Component | Implementation |
| --------- | -------------- |
| Read SIM serial | Existing `SimStatusService` + `MainActivity.getSimStatus` |
| Compare with registered SIM | `SimMonitorEngine` vs server baseline + `registered_sim_serial` prefs |
| Trigger theft mode | `SimController` sets `theftModeActive`, dashboard banner |
| Send emergency alert | `SimRepository.sendTheftAlert()` → SMS with theft template |
| Enrollment baseline | `DeviceInfoService` sends `simSerial`/`simOperator` on register |

### Trigger flow

```
SIM_STATE_CHANGED (Android) or 15s poll
   ↓
SimMonitorEngine._evaluate()
   ↓  (current.serial != registeredSerial)
SimController._onSimChange()
   ├─ POST /api/sim-changes  → DB + device.status = LOST
   └─ SMS ANTI-LEBA THEFT ALERT
```

## Backend API

| Method | Route | Auth | Description |
| ------ | ----- | ---- | ----------- |
| POST | `/api/sim-changes` | Bearer | Report SIM replacement |
| GET | `/api/sim-changes?deviceId=` | Bearer | List change history |

### POST body

```json
{
  "deviceId": "uuid",
  "clientEventId": "sim-1718450000000",
  "previousSerial": "8901…",
  "newSerial": "8902…",
  "previousOperator": "Ethio Telecom",
  "newOperator": "Safaricom",
  "detectedAt": "2026-06-15T12:00:00.000Z"
}
```

## Test plan

1. Enroll device with SIM inserted — verify `simSerial` stored on server
2. Start tracking — dashboard **SIM watch** shows baseline + monitoring active
3. Swap SIM (or use second SIM slot) — within seconds:
   - Dashboard shows **Theft mode active**
   - Log: `SIM change detected: … → …`
   - SMS received with `ANTI-LEBA THEFT ALERT`
4. Query `GET /api/sim-changes?deviceId=` — event present
5. `GET /api/devices` — device `status` is `LOST`

> **Note:** Samsung/Android may return `UNKNOWN` for SIM serial without `READ_PHONE_STATE`. Grant phone permissions. For dev testing without swapping SIM, temporarily change `registered_sim_serial` in app prefs.

## Module layout

```
features/sim/
├── domain/          sim_config, sim_repository
├── data/
│   ├── sim_monitor_engine.dart
│   ├── datasources/sim_remote_datasource.dart
│   └── repositories/sim_repository_impl.dart
└── presentation/providers/sim_providers.dart
```
