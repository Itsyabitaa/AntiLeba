# Sprint 9 — Remote Command System

**Duration**: 2 weeks · **Goal**: allow remote control of a lost device in real time.

## Deliverables

| Deliverable | Where |
| ----------- | ----- |
| WebSocket listener + command executor | `mobile/lib/features/remote_commands/` |
| WebSocket gateway + command service | `backend/src/modules/commands/` |
| Database table | `commands` |

## Acceptance criteria

- [x] Device receives commands (Socket.IO `/commands`, `command:execute` event)
- [x] Commands execute correctly (theft mode, live location, alarm, capture)
- [x] Unauthorized commands blocked (JWT + device ownership + session binding)

## Command types

| Type | Device action |
| ---- | ------------- |
| `ACTIVATE_THEFT_MODE` | Local theft banner + server marks device `LOST` |
| `REQUEST_LIVE_LOCATION` | Immediate GPS fix + upload |
| `TRIGGER_ALARM` | Alarm ringtone + vibration (15s default) |
| `CAPTURE_IMAGE` | Front camera evidence (`REMOTE_COMMAND` trigger) |

## Backend API

| Method | Route | Auth | Description |
| ------ | ----- | ---- | ----------- |
| POST | `/api/commands` | Bearer | Issue command to owned device |
| GET | `/api/commands?deviceId=` | Bearer | List command history |
| POST | `/api/commands/ack` | Bearer | Acknowledge command (REST fallback) |

### Issue body

```json
{
  "deviceId": "uuid",
  "type": "CAPTURE_IMAGE",
  "clientEventId": "optional-dedup-key",
  "payload": { "durationSeconds": 15 }
}
```

Response includes `delivered: boolean` (whether the device WS room was online).

## WebSocket (`/commands` namespace)

| Event | Direction | Payload |
| ----- | --------- | ------- |
| `device:register` | client → server | `{ deviceId }` — joins `device:{id}` room |
| `command:execute` | server → client | `{ id, deviceId, type, payload, issuedAt }` |
| `command:ack` | client → server | `{ commandId, deviceId, status, errorMessage? }` |

Auth: JWT in Socket.IO handshake `auth.token` (same bearer as REST).

## Flutter wiring

```
TrackingController.start()
   ↓
RemoteCommandController.start(deviceId)
   ↓
Socket.IO connect → device:register
   ↓
command:execute → RemoteCommandExecutor
   ↓
command:ack (ACKNOWLEDGED | FAILED)
```

Started/stopped with tracking lifecycle (logout stops WS).

## Test plan

1. Apply migration: `cd backend && npx prisma migrate deploy && npx prisma generate`
2. Restart backend once (only one instance on `:3000`)
3. `adb reverse tcp:3000 tcp:3000`
4. Run mobile app, log in, confirm dashboard **Remote commands** card shows *Listening*
5. Issue a command (replace `TOKEN` and `DEVICE_ID`):

```bash
curl -X POST http://localhost:3000/api/commands \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"DEVICE_ID","type":"TRIGGER_ALARM"}'
```

6. Verify alarm plays, dashboard shows last command + `acknowledged`
7. Try `CAPTURE_IMAGE`, `REQUEST_LIVE_LOCATION`, `ACTIVATE_THEFT_MODE`
8. Unauthorized test: use token from another user → `404 Device not found`

## Module layout

```
backend/src/modules/commands/
├── commands.module.ts
├── commands.controller.ts
├── commands.gateway.ts
├── commands.service.ts
├── ws-auth.service.ts
└── dto/

mobile/lib/features/remote_commands/
├── domain/
├── data/
│   ├── remote_command_websocket.dart
│   ├── remote_command_executor.dart
│   └── services/alarm_service.dart
└── presentation/providers/
```
