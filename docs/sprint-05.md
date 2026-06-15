# Sprint 5 — SMS Fallback System

**Duration**: 2 weeks · **Goal**: enable SMS-based emergency communication.

## Deliverables

| Deliverable              | Where                                              |
| ------------------------ | -------------------------------------------------- |
| SMS emergency alert module | `features/sms/` + Android `MainActivity` SIM channel |

## Acceptance criteria

- [x] SMS sent successfully without internet (cellular SMS via Android `SmsManager`)
- [x] SMS contains accurate data (lat, lng, battery %, SIM status, timestamp)
- [x] Retry mechanism works (Hive pending queue + 3 attempts with backoff)

## Flutter changes

| Component | Implementation |
| --------- | -------------- |
| Internet loss detection | `ConnectivityService` + `SmsFallbackEngine` listens for offline |
| Emergency SMS send | `SmsSendService` (Android `SmsManager` via platform channel) after runtime `Permission.sms` |
| Alert formatting | `SmsMessageFormatter` — compact multi-line body |
| Retry | Hive `pending_sms_alerts` + periodic 2-min retry + manual **Retry** on dashboard |
| Dedup | Hive `sent_sms_alerts` keyed by GPS `clientEventId` |
| Battery | `battery_plus` |
| SIM status | Android `MethodChannel` in `MainActivity.kt` |
| SIM change watch | `SharedPreferences` stores last SIM serial; dashboard shows change |

### SMS message format

```
ANTI-LEBA ALERT
Lat:9.01234 Lon:38.56789
Batt:78% SIM:READY · Ethio Telecom
Time:2026-06-15 10:30:00 UTC
ID:a1b2c3d4
```

### Trigger conditions

1. GPS fix collected while **offline** → immediate SMS attempt
2. Connectivity drops while tracking → SMS for last known fix
3. HTTP sync fails with pending data while offline → SMS fallback
4. Failed sends queued → auto-retry every 2 minutes (up to 3 attempts)

## Configuration

Set the emergency recipient at build/run time:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=EMERGENCY_SMS_NUMBER=+251911234567
```

> Use E.164 format without spaces. SMS works over cellular even when mobile data / Wi‑Fi data is unavailable.

## Permissions

Manifest already declares `SEND_SMS`, `READ_PHONE_STATE`. Runtime `Permission.sms` is requested on first alert.

## Test plan

1. Configure `EMERGENCY_SMS_NUMBER` to a test handset
2. Login, reach dashboard (tracking + SMS engine start)
3. Enable airplane mode, **disable Wi‑Fi only** if testing on Wi‑Fi-only offline — for true SMS test use airplane mode with cellular radio available, or disable mobile data + Wi‑Fi
4. Wait for GPS sample — dashboard **SMS fallback** shows send activity
5. Verify received SMS contains coordinates, battery, SIM status, timestamp
6. Block SMS (deny permission) — alert queues; tap **Retry** after granting permission
7. Re-trigger same location — dedup prevents duplicate SMS (`skipped`)

## Architecture

```
GPS fix (offline)
   ↓
SmsFallbackEngine.onLocationCollected()
   ↓
SmsRepository.sendEmergencyAlert()
   ├─ BatteryStatusService
   ├─ SimStatusService (platform channel)
   ├─ SmsMessageFormatter
   └─ SmsSendService → cellular SMS
   ↓
success → sent_sms_alerts Hive box
failure → pending_sms_alerts + retry engine
```

## Module layout

```
features/sms/
├── domain/          sms_alert, sms_config, sms_repository, sms_send_result
├── data/
│   ├── datasources/sms_local_datasource.dart
│   ├── services/    battery, sim, permissions, send, formatter
│   ├── repositories/sms_repository_impl.dart
│   └── sms_fallback_engine.dart
└── presentation/providers/sms_providers.dart
```
