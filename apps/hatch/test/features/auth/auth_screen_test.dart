import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatch/auth/auth_repository.dart';
import 'package:hatch/features/auth/auth_screen.dart';
import 'package:hatch/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

final class _FakeAuthRepository implements AuthRepository {
  final List<String> magicLinkCalls = [];
  int googleSignInCalls = 0;
  int appleSignInCalls = 0;
  bool shouldThrow = false;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Session? get currentSession => null;

  @override
  User? get currentUser => null;

  @override
  Future<void> signInWithMagicLink(String email) async {
    if (shouldThrow) throw Exception('network error');
    magicLinkCalls.add(email);
  }

  @override
  Future<void> signInWithGoogle() async {
    if (shouldThrow) throw Exception('google error');
    googleSignInCalls++;
  }

  @override
  Future<void> signInWithApple() async {
    if (shouldThrow) throw Exception('apple error');
    appleSignInCalls++;
  }

  @override
  Future<void> signOut() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildApp(_FakeAuthRepository repo) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: const MaterialApp(
      home: AuthScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AuthScreen', () {
    testWidgets('shows three sign-in buttons', (tester) async {
      await tester.pumpWidget(_buildApp(_FakeAuthRepository()));

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with email'), findsOneWidget);
    });

    // --- Google Sign-In ---

    testWidgets('tapping Continue with Google calls signInWithGoogle',
        (tester) async {
      final repo = _FakeAuthRepository();
      await tester.pumpWidget(_buildApp(repo));

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      await tester.pump();

      expect(repo.googleSignInCalls, equals(1));
    });

    testWidgets('shows snackbar when Google sign-in throws', (tester) async {
      final repo = _FakeAuthRepository()..shouldThrow = true;
      await tester.pumpWidget(_buildApp(repo));

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('google error'), findsOneWidget);
    });

    // --- Apple Sign-In ---

    testWidgets('tapping Continue with Apple calls signInWithApple',
        (tester) async {
      final repo = _FakeAuthRepository();
      await tester.pumpWidget(_buildApp(repo));

      await tester.tap(find.text('Continue with Apple'));
      await tester.pump();
      await tester.pump();

      expect(repo.appleSignInCalls, equals(1));
    });

    testWidgets('shows snackbar when Apple sign-in throws', (tester) async {
      final repo = _FakeAuthRepository()..shouldThrow = true;
      await tester.pumpWidget(_buildApp(repo));

      await tester.tap(find.text('Continue with Apple'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('apple error'), findsOneWidget);
    });

    // --- Magic link ---

    testWidgets('tapping Continue with email reveals email field',
        (tester) async {
      await tester.pumpWidget(_buildApp(_FakeAuthRepository()));

      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Continue with email'));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows error for empty email without calling repository',
        (tester) async {
      final repo = _FakeAuthRepository();
      await tester.pumpWidget(_buildApp(repo));

      await tester.tap(find.text('Continue with email'));
      await tester.pump();

      await tester.tap(find.text('Send magic link'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(repo.magicLinkCalls, isEmpty);
    });

    testWidgets('shows error for email missing @', (tester) async {
      final repo = _FakeAuthRepository();
      await tester.pumpWidget(_buildApp(repo));

      await tester.tap(find.text('Continue with email'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'notanemail');
      await tester.tap(find.text('Send magic link'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(repo.magicLinkCalls, isEmpty);
    });

    testWidgets('calls signInWithMagicLink with trimmed email on valid input',
        (tester) async {
      final repo = _FakeAuthRepository();
      await tester.pumpWidget(_buildApp(repo));

      await tester.tap(find.text('Continue with email'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '  test@example.com  ');
      await tester.tap(find.text('Send magic link'));
      await tester.pump();
      await tester.pump();

      expect(repo.magicLinkCalls, equals(['test@example.com']));
    });

    testWidgets('shows snackbar on success and hides email field',
        (tester) async {
      final repo = _FakeAuthRepository();
      await tester.pumpWidget(_buildApp(repo));

      await tester.tap(find.text('Continue with email'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.tap(find.text('Send magic link'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Check your inbox — tap the link to sign in'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('shows snackbar on repository error', (tester) async {
      final repo = _FakeAuthRepository()..shouldThrow = true;
      await tester.pumpWidget(_buildApp(repo));

      await tester.tap(find.text('Continue with email'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.tap(find.text('Send magic link'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('network error'), findsOneWidget);
    });
  });
}
