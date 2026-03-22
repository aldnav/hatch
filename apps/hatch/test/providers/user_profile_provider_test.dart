import 'package:core/core.dart' as core;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatch/providers/auth_provider.dart';
import 'package:hatch/providers/user_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

// ---------------------------------------------------------------------------
// Test fixture
// ---------------------------------------------------------------------------

const _fakeAuthUser = User(
  id: 'test-id',
  appMetadata: <String, dynamic>{},
  userMetadata: <String, dynamic>{},
  aud: 'authenticated',
  createdAt: '2024-01-01T00:00:00.000Z',
  email: 'test@example.com',
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('userProfileProvider', () {
    test('emits null when no user is signed in', () async {
      final db = core.AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          core.appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final values = <AsyncValue<core.User?>>[];
      container.listen<AsyncValue<core.User?>>(
        userProfileProvider,
        (_, next) => values.add(next),
        fireImmediately: true,
      );

      await Future<void>.delayed(Duration.zero);

      // Provider emits a stream; when auth user is null it returns
      // Stream.value(null) which should resolve to null.
      final lastValue = values.last;
      expect(lastValue.valueOrNull, isNull);
    });

    test('emits null when signed-in user has no profile row', () async {
      final db = core.AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(_fakeAuthUser),
          core.appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final values = <AsyncValue<core.User?>>[];
      container.listen<AsyncValue<core.User?>>(
        userProfileProvider,
        (_, next) => values.add(next),
        fireImmediately: true,
      );

      await Future<void>.delayed(Duration.zero);

      final lastValue = values.last;
      // No profile row inserted — should be null.
      expect(lastValue.valueOrNull, isNull);
    });

    test('emits profile row after upsert', () async {
      final db = core.AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(_fakeAuthUser),
          core.appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final emitted = <core.User?>[];
      container.listen<AsyncValue<core.User?>>(
        userProfileProvider,
        (_, next) {
          if (next is AsyncData<core.User?>) emitted.add(next.value);
        },
        fireImmediately: true,
      );

      await Future<void>.delayed(Duration.zero);

      // Insert the profile row.
      await db.usersDao.upsertUser(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
      );

      await Future<void>.delayed(Duration.zero);

      expect(emitted.last, isNotNull);
      expect(emitted.last!.name, equals('Test User'));
      expect(emitted.last!.email, equals('test@example.com'));
    });
  });
}
