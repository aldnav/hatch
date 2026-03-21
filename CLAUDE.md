# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Hatch is a free, open-source, self-hostable travel planner built with Flutter and Dart.

## Common Commands

```bash
# Bootstrap all packages (run once after clone, and after pubspec changes)
dart pub global activate melos
melos bootstrap

# Codegen — must run after changing Drift tables or Riverpod providers
melos run codegen
melos run codegen:watch   # watch mode during development

# Run the app (from apps/hatch/)
flutter run --dart-define=SUPABASE_URL=http://localhost:8000 \
            --dart-define=SUPABASE_ANON_KEY=<key>

# Test
melos run test
melos run test:coverage
flutter test test/widget_test.dart   # single file

# Lint & format
melos run analyze
melos run format
melos run format:check    # CI-style, exits 1 if dirty

# Build
melos run build:android
melos run build:ios
melos run build:web

# Self-hosted backend (Docker)
cp .env.example .env      # fill in secrets
docker compose -f docker/docker-compose.yml up -d
```

## Architecture

### Monorepo layout

| Path | Kind | Purpose |
|------|------|---------|
| `apps/hatch` | Flutter app | Screens, routing, platform entry point |
| `packages/core` | Dart package | Drift DB schema, Riverpod providers, business logic |
| `packages/ui` | Flutter package | Shared widgets |
| `docker/` | Docker Compose | Self-hosted Supabase backend |

`packages/core` has **no Flutter dependency** — it uses plain `riverpod`/`drift`. Platform-specific code (`sqlite3_flutter_libs`, `path_provider`) lives only in `apps/hatch`.

### State management (Riverpod)

Use `@riverpod` codegen for all providers. `keepAlive: true` only for long-lived singletons (`appDatabaseProvider`, `routerProvider`). Providers in `packages/core` import `riverpod`/`riverpod_annotation` only.

### Navigation (GoRouter)

Route names are constants in `apps/hatch/lib/router/router.dart` → `Routes`. The `GoRouter` instance is itself a Riverpod provider (`routerProvider`) so it can read auth state. Auth redirect and `refreshListenable` live in the router — not in screens. Deep link scheme: `hatch://`.

Route hierarchy:
```
/auth               → AuthScreen
/home               → HomeScreen
  /home/trip/:id    → TripDetailScreen
/settings           → SettingsScreen
```

### Database (Drift)

`AppDatabase` is defined in `packages/core` and injected into the Riverpod tree via `ProviderScope.overrides` in `apps/hatch/lib/main.dart`. All 12 tables extend `TimestampedTable` (mixin providing `id` UUID, `created_at`, `updated_at`, `hlc`).

Tables: `users`, `trips`, `trip_days`, `activities`, `places`, `flights`, `hotels`, `notes`, `expenses`, `attachments`, `collaborators`, `sync_log`.

After changing any table: run `melos run codegen`. To add a migration: increment `schemaVersion` in `AppDatabase` and add an `onUpgrade` branch — never edit `onCreate`.

### Backend (Supabase, self-hosted)

`docker/docker-compose.yml` runs PostgreSQL+pgvector, Supabase Auth, Realtime, Storage (S3 via MinIO), and Kong as API gateway. The Flutter app connects via `--dart-define=SUPABASE_URL` and `SUPABASE_ANON_KEY`. RLS policies in `docker/supabase/migrations/` mirror the Drift schema.
