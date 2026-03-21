# Contributing to Hatch

## Setup

```bash
# Install Melos globally
dart pub global activate melos

# Install lefthook (pre-commit hooks)
brew install lefthook   # macOS
# or: npm install -g lefthook

# Bootstrap all packages and install hooks
melos bootstrap
lefthook install
```

After bootstrap, run codegen once before starting the app:

```bash
melos run codegen
```

## Monorepo structure

| Path | Purpose |
|------|---------|
| `apps/hatch` | Flutter application — routing, screens, platform entry point |
| `packages/core` | Plain Dart package — Drift DB schema, Riverpod providers, business logic |
| `packages/ui` | Flutter package — shared widgets consumed by `apps/hatch` |
| `docker/` | Self-hosted Supabase Docker Compose stack |

## State management conventions (Riverpod)

- Use `@riverpod` codegen for all providers (`riverpod_generator`). Avoid manually typed `Provider(...)` constructors.
- `keepAlive: true` only for providers that must survive widget rebuilds (e.g. `appDatabaseProvider`, `routerProvider`).
- Providers in `packages/core` depend only on `riverpod`/`riverpod_annotation` (not `flutter_riverpod`) so the package stays Flutter-free.
- The `AppDatabase` is constructed in `apps/hatch/lib/main.dart` and injected via `ProviderScope.overrides`. Never import `sqlite3_flutter_libs` or `path_provider` from `packages/core`.

## Navigation conventions (GoRouter)

- All route names are constants in `apps/hatch/lib/router/router.dart` under `Routes`.
- Navigate with named routes: `context.goNamed(Routes.tripDetail, pathParameters: {'id': tripId})`.
- Auth redirect logic lives exclusively in the `GoRouter.redirect` callback — do not add nav logic inside screens.
- Deep link scheme: `hatch://`. Register new paths in `AndroidManifest.xml` and `Info.plist` when adding deep-linkable routes.

## Database conventions (Drift)

- All tables mix in `TimestampedTable` (`packages/core/lib/src/database/tables/shared_columns.dart`), which provides `id` (UUID), `created_at`, `updated_at`, and `hlc`.
- `id` is always a client-generated UUID v4 (`clientDefault`), not a server sequence.
- `hlc` stores a Hybrid Logical Clock string for the sync engine (M4). Format: `<ISO-8601>-<counter>-<node-id>`. Leave empty until the sync module is implemented.
- Generated `.g.dart` files are excluded from version control. Always run `melos run codegen` after changing table definitions.
- Schema migrations: increment `schemaVersion` in `AppDatabase` and add an `onUpgrade` case — never modify existing `onCreate` logic.

## Running tests

```bash
melos run test                  # all packages
flutter test test/widget_test.dart   # single file (from apps/hatch/)
```

## Code style

Formatting and analysis are enforced by the pre-commit hook. To run manually:

```bash
melos run format        # fix in place
melos run format:check  # CI-style check (exit 1 if dirty)
melos run analyze
```
