# Anti-Leba Web Dashboard

React + Vite monitoring dashboard for enrolled devices.

## Features

- Live device map (OpenStreetMap + Leaflet)
- Location history table
- Alert history (SIM changes, remote commands, theft mode)
- Evidence photo gallery (authenticated file download)
- Theft mode controls (status + remote commands)

## Setup

```bash
cd dashboard
npm install
cp .env.example .env
npm run dev
```

Open http://localhost:5173 and sign in with the same owner account used in the mobile app.

Ensure backend `CORS_ORIGINS` includes `http://localhost:5173`.

## Environment

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `VITE_API_URL` | `http://localhost:3000/api` | NestJS API base URL |

Live data refreshes every 12 seconds via polling.
