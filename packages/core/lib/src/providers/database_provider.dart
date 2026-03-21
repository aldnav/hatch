import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';

part 'database_provider.g.dart';

/// Provides the [AppDatabase] instance.
///
/// This provider must be overridden in the app's [ProviderScope] with a
/// concrete [AppDatabase] backed by a platform [QueryExecutor].
/// Keeping the executor construction in `apps/hatch` ensures `packages/core`
/// stays Flutter-free.
///
/// Example override in `apps/hatch/lib/main.dart`:
/// ```dart
/// ProviderScope(
///   overrides: [
///     appDatabaseProvider.overrideWithValue(AppDatabase(executor)),
///   ],
///   child: const HatchApp(),
/// )
/// ```
@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden in ProviderScope.',
  );
}
