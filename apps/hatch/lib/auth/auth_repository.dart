import 'package:supabase_flutter/supabase_flutter.dart';

/// Contract for all authentication operations.
///
/// Lives in `apps/hatch` (not `packages/core`) because it depends on
/// Supabase types that must not leak into the Flutter-free core package.
abstract interface class AuthRepository {
  /// Stream of auth state changes (sign-in, sign-out, token refresh, …).
  Stream<AuthState> get authStateChanges;

  /// The currently active session, or null when signed out.
  Session? get currentSession;

  /// The currently signed-in user, or null when signed out.
  User? get currentUser;

  /// Sends a magic-link email to [email]. Requires PKCE auth flow.
  Future<void> signInWithMagicLink(String email);

  /// Signs in with a Google account.
  Future<void> signInWithGoogle();

  /// Signs in with an Apple ID.
  Future<void> signInWithApple();

  /// Signs out the current user.
  Future<void> signOut();
}
