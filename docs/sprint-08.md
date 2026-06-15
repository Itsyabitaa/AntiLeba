# Sprint 8 — Camera Evidence Capture

**Duration**: 2 weeks · **Goal**: capture suspicious user images as theft evidence.

## Deliverables

| Deliverable | Where |
| ----------- | ----- |
| Evidence capture module | `features/photos/` + `camera` package |
| Image upload API | `backend/src/modules/photos/` |
| Database table | `photos` |

## Acceptance criteria

- [x] Photos captured correctly (front camera via `camera` package)
- [x] Photos uploaded successfully (`POST /api/photos` multipart)
- [x] Local storage fallback works (filesystem + Hive `pending_photos` queue)

## Flutter changes

| Component | Implementation |
| --------- | -------------- |
| Front camera capture | `CameraCaptureService` — `CameraLensDirection.front` |
| Local storage | App documents `evidence/{deviceId}/` + Hive metadata queue |
| Upload | `PhotoRemoteDataSource` — Dio `FormData` multipart |
| Retry | `PhotoSyncEngine` — 2-min interval, 3 attempts |
| Triggers | SIM replacement (wired), manual dashboard button; remote command / unlock failure APIs ready |

### Trigger flow

```
SIM change / manual Capture / future remote command
   ↓
PhotoRepository.captureFrontPhoto()
   ↓
Local JPEG + Hive pending_photos
   ↓
PhotoSyncEngine → POST /api/photos (multipart)
   ↓
success → delete local file + remove from queue
```

## Backend API

| Method | Route | Auth | Description |
| ------ | ----- | ---- | ----------- |
| POST | `/api/photos` | Bearer | Multipart upload (`file` + metadata) |
| GET | `/api/photos?deviceId=` | Bearer | List photo metadata |

### Multipart fields

| Field | Type | Required |
| ----- | ---- | -------- |
| `file` | image/jpeg (max 5 MB) | yes |
| `deviceId` | UUID | yes |
| `trigger` | `SIM_REPLACEMENT` \| `REMOTE_COMMAND` \| `UNLOCK_FAILURE` \| `MANUAL` | yes |
| `capturedAt` | ISO-8601 | yes |
| `clientEventId` | string (dedup key) | optional |

Files stored under `backend/uploads/photos/{userId}/{deviceId}/`.

## Test plan

1. Grant camera permission when prompted on dashboard
2. Tap **Capture** on Evidence card — verify local pending count
3. With backend running — pending clears after upload (`last upload` timestamp)
4. Swap SIM (or simulate theft mode) — auto-capture after SMS alert
5. Stop backend, capture again — photo stays pending; tap **Upload** after restart
6. `GET /api/photos?deviceId=` returns metadata rows

## Module layout

```
features/photos/
├── domain/          photo_trigger, photo_config, photo_repository
├── data/
│   ├── services/    camera_permission, camera_capture
│   ├── datasources/ photo_local, photo_remote
│   ├── repositories/photo_repository_impl.dart
│   └── photo_sync_engine.dart
└── presentation/providers/photo_providers.dart
```
