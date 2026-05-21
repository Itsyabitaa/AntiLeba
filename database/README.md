# Database — PostgreSQL

Owns the schema for the Smart Anti-Theft Recovery System.

## Sprint 1 tables

| Table     | Purpose                                                       |
| --------- | ------------------------------------------------------------- |
| `users`   | Account credentials, role, contact info                        |
| `devices` | Devices enrolled by a user (Android ID, SIM, FCM token, etc.) |

## Bootstrap

There are two equivalent ways to provision the schema. Pick whichever you
prefer — Prisma is the source of truth for the backend, `init.sql` is a
plain reference / fallback.

### Option A — Prisma (recommended, mirrors backend code)

```bash
cd backend
cp .env.example .env       # set DATABASE_URL
npx prisma migrate dev --name init
```

### Option B — Raw SQL

```bash
createdb anti_leba           # or use your existing database
psql -d anti_leba -f database/init.sql
```

## Future sprint tables (placeholders)

`locations`, `images`, `commands`, `alerts`, `logs` — added in later sprints.
