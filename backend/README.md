# Anti-Leba — Backend (NestJS)

API for the Smart Anti-Theft Recovery System. NestJS 11 + TypeScript (strict)
+ Prisma 6 (PostgreSQL) + Passport JWT.

> For monorepo-wide instructions see the [root README](../README.md).

## Layout

```
src/
├── main.ts                      # bootstrap, global pipes/prefix/CORS
├── app.module.ts                # composition root
├── config/
│   └── env.validation.ts        # class-validator schema for .env
├── prisma/
│   ├── prisma.module.ts         # @Global Prisma module
│   └── prisma.service.ts        # PrismaClient + non-blocking $connect
└── modules/
    ├── auth/
    │   ├── auth.controller.ts   # /api/auth/{register,login,me}
    │   ├── auth.service.ts
    │   ├── auth.module.ts       # registers global JwtAuthGuard
    │   ├── decorators/          # @Public, @CurrentUser
    │   ├── dto/                 # RegisterDto, LoginDto
    │   ├── guards/jwt-auth.guard.ts
    │   ├── strategies/jwt.strategy.ts
    │   └── types/auth-user.type.ts
    ├── users/
    │   ├── users.module.ts
    │   └── users.service.ts
    ├── devices/devices.module.ts (stub — fleshed out in Sprint 2)
    └── health/health.controller.ts (/api/health)

prisma/
└── schema.prisma                # User + Device models
```

## Local dev

```bash
cp .env.example .env             # fill in DATABASE_URL + JWT_SECRET
npm install
npx prisma generate
npx prisma migrate dev --name init   # creates users + devices
npm run start:dev                # nest start --watch
```

## Available scripts

| Script             | What it does                            |
| ------------------ | --------------------------------------- |
| `npm run start`    | Run compiled output                     |
| `npm run start:dev`| Watch mode (nest start --watch)         |
| `npm run build`    | TypeScript build (`dist/`)              |
| `npm run lint`     | ESLint + autofix                        |
| `npm run test`     | Jest unit tests                         |
| `npm run test:e2e` | Jest e2e (needs `.env` + DB)            |

## Env variables

| Key              | Required | Notes                                          |
| ---------------- | -------- | ---------------------------------------------- |
| `NODE_ENV`       | no       | `development` / `production` / `test`           |
| `PORT`           | no       | defaults to `3000`                              |
| `DATABASE_URL`   | **yes**  | PostgreSQL connection string                    |
| `JWT_SECRET`     | **yes**  | ≥ 16 chars; rotate per environment              |
| `JWT_EXPIRES_IN` | no       | `1d`, `15m`, etc. (jsonwebtoken format)         |
| `CORS_ORIGINS`   | no       | Comma-separated allowlist                       |

Invalid env vars throw on boot (see `src/config/env.validation.ts`).

## Security defaults

- **Protected by default**: a global `JwtAuthGuard` is registered via
  `APP_GUARD`; routes opt out with `@Public()`.
- **bcrypt(rounds=12)** for password hashing.
- **class-validator** ValidationPipe with `whitelist + forbidNonWhitelisted`.
