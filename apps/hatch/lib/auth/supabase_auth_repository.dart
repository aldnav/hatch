import 'package:hatch/auth/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-backed implementation of [AuthRepository].
///
/// Sign-in methods for Google, Apple, and magic link are stubs until
/// issues #10–#12 are implemented.
final class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<void> signInWithMagicLink(String email) =>
      throw UnimplementedError('Magic link sign-in — see issue #10');

  @override
  Future<void> signInWithGoogle() =>
      throw UnimplementedError('Google sign-in — see issue #11');

  @override
  Future<void> signInWithApple() =>
      throw UnimplementedError('Apple sign-in — see issue #12');

  @override
  Future<void> signOut() => _client.auth.signOut();
}
