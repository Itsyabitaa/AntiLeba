# Sprint 10 — Dashboard System

**Duration**: 2 weeks · **Goal**: web dashboard for monitoring devices.

## Deliverables

| Deliverable | Where |
| ----------- | ----- |
| Monitoring dashboard | `dashboard/` (React + Vite) |
| Dashboard APIs | `backend/src/modules/dashboard/` |
| Statistics APIs | `GET /api/dashboard/stats`, included in overview |
| Photo file serving | `GET /api/photos/:id/file` |
| Device status controls | `PATCH /api/devices/:id/status` |

## Acceptance criteria

- [x] Devices visible on dashboard (overview + map markers)
- [x] Live data updates correctly (12s polling)
- [x] Alerts displayed properly (SIM, commands, LOST status)

## Dashboard features

| Feature | Implementation |
| ------- | -------------- |
| Live device map | Leaflet map with latest fix per device |
| Location history | `GET /api/locations?deviceId=` |
| Alert history | `GET /api/dashboard/alerts` |
| Image gallery | `GET /api/photos` + authenticated `/:id/file` |
| Theft mode controls | Status PATCH + `POST /api/commands` |

## Backend API

| Method | Route | Description |
| ------ | ----- | ----------- |
| GET | `/api/dashboard/overview` | Devices + last location + stats |
| GET | `/api/dashboard/stats` | Aggregate counters |
| GET | `/api/dashboard/alerts?limit=` | Unified alert feed |
| PATCH | `/api/devices/:id/status` | Set ACTIVE / LOST / RECOVERED / DISABLED |
| GET | `/api/photos/:id/file` | Download evidence JPEG/PNG |

## Test plan

1. Backend running with `CORS_ORIGINS` including `http://localhost:5173`
2. `cd dashboard && npm install && npm run dev`
3. Sign in with owner credentials
4. Confirm devices appear on map and stats cards populate
5. Select a device — location history and photo gallery load
6. Trigger mobile activity (GPS sync, SIM change, photo capture) — alerts update within ~12s
7. Use theft controls — mark LOST / issue remote command — verify mobile responds

## Stack

- **Frontend**: React 19, Vite 6, Leaflet
- **Backend**: NestJS dashboard module (no new DB tables — aggregates existing data)
