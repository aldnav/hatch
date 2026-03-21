import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

/// Returns true when the Supabase singleton has been initialised.
///
/// Using a try/catch is necessary because [Supabase.instance] throws an
/// [AssertionError] in debug mode when called before [Supabase.initialize].
bool _supabaseReady() {
  try {
    return Supabase.instance.isInitialized;
  } on AssertionError {
    return false;
  }
}

/// Emits the current Supabase [Session] (or null when signed out).
@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(AuthStateChangesRef ref) {
  if (!_supabaseReady()) return const Stream.empty();
  return Supabase.instance.client.auth.onAuthStateChange;
}

/// True when the user has an active session.
@Riverpod(keepAlive: true)
bool isAuthenticated(IsAuthenticatedRef ref) {
  if (!_supabaseReady()) return false;
  final session = Supabase.instance.client.auth.currentSession;
  return session != null;
}
