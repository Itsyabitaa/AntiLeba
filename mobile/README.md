# Anti-Leba — Mobile (Flutter)

Smart Anti-Theft Recovery System, mobile client. Riverpod + GoRouter + Dio,
clean-architecture layout.

## Quick start

```bash
# 1. Install Flutter dependencies
flutter pub get

# 2. (Optional) point the app at your backend
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   # Android emulator
flutter run --dart-define=API_BASE_URL=http://localhost:3000  # iOS simulator

# 3. Run
flutter run
```

> On a **real Android device**, replace `10.0.2.2` with your dev machine's
> LAN IP, e.g. `--dart-define=API_BASE_URL=http://192.168.1.50:3000`.

## Project layout

```
lib/
├── app.dart                 # MaterialApp.router shell
├── main.dart                # entry point, ProviderScope, bootstrap
├── core/
│   ├── bootstrap.dart       # one-shot init (orientation, error capture)
│   ├── env/                 # compile-time env (--dart-define)
│   ├── errors/              # Failure hierarchy
│   ├── logging/             # AppLogger singleton
│   ├── network/             # Dio client + interceptors
│   ├── router/              # GoRouter config (AppRoutes)
│   └── theme/               # Material 3 light + dark themes
└── features/
    ├── auth/
    │   ├── domain/          # AuthRepository, AuthSession
    │   └── presentation/    # Login + Register screens
    ├── dashboard/
    │   └── presentation/
    ├── devices/
    │   └── domain/          # Device model
    └── splash/
        └── presentation/
```

Each feature is intended to follow `data/` (DTOs, remote/local sources,
repository impls) + `domain/` (entities, contracts) + `presentation/`
(widgets, controllers/Notifiers).

## State management

[Riverpod](https://riverpod.dev) is the source of truth. Providers live next
to the feature that owns them; cross-cutting providers live under `core/`.

## Android permissions

Configured in `android/app/src/main/AndroidManifest.xml` for: GPS (fine,
coarse, background), SMS (send/receive), camera, microphone, foreground
service (location + data-sync), storage/media, network state, boot receiver,
post-notifications.

These are **manifest declarations only** — runtime permissions will be
requested in the relevant feature flows (Sprint 3+).

## Roadmap

This is Sprint 1 — base project, theming, navigation skeleton. Subsequent
sprints flesh out: SMS fallback, background location, offline buffer, remote
commands, evidence capture, sync.
