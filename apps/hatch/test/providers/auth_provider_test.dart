import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatch/auth/auth_repository.dart';
import 'package:hatch/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

const _fakeUser = User(
  id: 'test-user-id',
  appMetadata: <String, dynamic>{},
  userMetadata: <String, dynamic>{},
  aud: 'authenticated',
  createdAt: '2024-01-01T00:00:00.000Z',
  email: 'test@example.com',
);

// Session does not have a const constructor.
final _fakeSession = Session(
  accessToken: 'fake-access-token',
  tokenType: 'bearer',
  user: _fakeUser,
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [ProviderContainer] that overrides [authStateChangesProvider]
/// with [stream] and registers [addTearDown] for cleanup.
ProviderContainer _containerWith(Stream<AuthState> stream) {
  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith((_) => stream),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('isAuthenticatedProvider', () {
    test('is false while stream is in loading state (no value emitted yet)',
        () {
      final container = _containerWith(const Stream.empty());
      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    test('is false when stream emits a signed-out event (null session)',
        () async {
      final controller = StreamController<AuthState>();
      addTearDown(controller.close);
      final container = _containerWith(controller.stream)
        ..listen(isAuthenticatedProvider, (_, __) {});

      controller.add(const AuthState(AuthChangeEvent.signedOut, null));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    test('is true when stream emits a signed-in event with a session',
        () async {
      final controller = StreamController<AuthState>();
      addTearDown(controller.close);
      final container = _containerWith(controller.stream)
        ..listen(isAuthenticatedProvider, (_, __) {});

      controller.add(AuthState(AuthChangeEvent.signedIn, _fakeSession));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isAuthenticatedProvider), isTrue);
    });

    test('transitions true → false when stream emits sign-out after sign-in',
        () async {
      final controller = StreamController<AuthState>();
      addTearDown(controller.close);
      final container = _containerWith(controller.stream)
        ..listen(isAuthenticatedProvider, (_, __) {});

      controller.add(AuthState(AuthChangeEvent.signedIn, _fakeSession));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(isAuthenticatedProvider), isTrue);

      controller.add(const AuthState(AuthChangeEvent.signedOut, null));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(isAuthenticatedProvider), isFalse);
    });
  });

  group('currentUserProvider', () {
    test('is null while stream is in loading state', () {
      final container = _containerWith(const Stream.empty());
      expect(container.read(currentUserProvider), isNull);
    });

    test('is null when stream emits a signed-out event', () async {
      final controller = StreamController<AuthState>();
      addTearDown(controller.close);
      final container = _containerWith(controller.stream)
        ..listen(currentUserProvider, (_, __) {});

      controller.add(const AuthState(AuthChangeEvent.signedOut, null));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(currentUserProvider), isNull);
    });

    test('returns the user when stream emits a signed-in event', () async {
      final controller = StreamController<AuthState>();
      addTearDown(controller.close);
      final container = _containerWith(controller.stream)
        ..listen(currentUserProvider, (_, __) {});

      controller.add(AuthState(AuthChangeEvent.signedIn, _fakeSession));
      await Future<void>.delayed(Duration.zero);

      final user = container.read(currentUserProvider);
      expect(user?.id, equals('test-user-id'));
      expect(user?.email, equals('test@example.com'));
    });

    test('becomes null again after a sign-out event', () async {
      final controller = StreamController<AuthState>();
      addTearDown(controller.close);
      final container = _containerWith(controller.stream)
        ..listen(currentUserProvider, (_, __) {});

      controller.add(AuthState(AuthChangeEvent.signedIn, _fakeSession));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(currentUserProvider), isNotNull);

      controller.add(const AuthState(AuthChangeEvent.signedOut, null));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(currentUserProvider), isNull);
    });
  });

  group('authRepositoryProvider', () {
    test('can be overridden with a fake implementation in tests', () {
      final fakeRepo = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      expect(container.read(authRepositoryProvider), same(fakeRepo));
    });
  });
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Minimal [AuthRepository] fake for use in tests.
final class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Session? get currentSession => null;

  @override
  User? get currentUser => null;

  @override
  Future<void> signInWithMagicLink(String email) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signOut() async {}
}
