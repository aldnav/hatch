# Hatch

**Free, open-source, self-hostable travel planner**

[![CI](https://github.com/aldnav/hatch/actions/workflows/ci.yml/badge.svg)](https://github.com/aldnav/hatch/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter 3.22](https://img.shields.io/badge/Flutter-3.22.0-02569B?logo=flutter)](https://flutter.dev)

## Overview

Hatch is a travel planner you can run entirely on your own infrastructure. It is built with Flutter and Dart, targeting Android, iOS, and web from a single codebase. All trip data is stored locally in a Drift (SQLite) database, making the app fully functional offline. Every record carries a Hybrid Logical Clock (HLC) timestamp so changes merge correctly when connectivity is restored. The optional self-hosted backend is a standard Supabase stack deployed via Docker Compose, providing auth, real-time sync, file storage, and row-level security — no third-party cloud required.

## Screenshots

Screenshots coming in M3.

---

## Self-hosting quickstart

**Prerequisites:** Docker and Docker Compose.

```bash
cp .env.example .env          # fill in secrets
docker compose -f docker/docker-compose.yml up -d
```

The stack starts PostgreSQL with pgvector, Supabase Auth, Realtime, Storage (backed by MinIO), and Kong as the API gateway. The Flutter app connects via `SUPABASE_URL` and `SUPABASE_ANON_KEY` supplied at build time (see Developer setup below).

---

## Developer setup

**Prerequisites:** Flutter >= 3.22, Dart >= 3.4, Melos, Lefthook.

```bash
# Install tooling
dart pub global activate melos
brew install lefthook          # macOS; or: npm install -g lefthook

# Clone and bootstrap
git clone https://github.com/aldnav/hatch && cd hatch
melos bootstrap
lefthook install

# Generate Drift and Riverpod code (required before first run)
melos run codegen

# Run the app (point at your local Supabase instance)
cd apps/hatch
flutter run --dart-define=SUPABASE_URL=http://localhost:8000 \
            --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

### Common tasks

```bash
# Re-run codegen after changing Drift tables or Riverpod providers
melos run codegen
melos run codegen:watch   # watch mode during development

# Tests
melos run test
melos run test:coverage

# Lint and format
melos run analyze
melos run format
melos run format:check    # exits 1 if dirty (used in CI)

# Production builds
melos run build:android
melos run build:ios
melos run build:web
```

---

## Monorepo structure

| Path | Purpose |
|------|---------|
| `apps/hatch` | Flutter application — routing, screens, platform entry point |
| `packages/core` | Drift DB schema, Riverpod providers, business logic (no Flutter dependency) |
| `packages/ui` | Shared widgets consumed by `apps/hatch` |
| `docker/` | Self-hosted Supabase Docker Compose stack |

`packages/core` is a plain Dart package with no Flutter dependency. Platform-specific code (`sqlite3_flutter_libs`, `path_provider`) lives only in `apps/hatch`. The `AppDatabase` is constructed in `apps/hatch/lib/main.dart` and injected into the Riverpod tree via `ProviderScope.overrides`.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions, coding conventions, and contribution guidelines.

---

## License

MIT. See [LICENSE](LICENSE).
