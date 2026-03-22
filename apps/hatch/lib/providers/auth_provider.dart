import 'package:hatch/auth/auth_repository.dart';
import 'package:hatch/auth/supabase_auth_repository.dart';
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
  } catch (_) {
    return false;
  }
}

/// Emits every [AuthState] change from Supabase (sign-in, sign-out, refresh).
///
/// All downstream providers derive from this stream so the entire auth state
/// tree rebuilds reactively on every auth event.
@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(AuthStateChangesRef ref) {
  if (!_supabaseReady()) return const Stream.empty();
  return Supabase.instance.client.auth.onAuthStateChange;
}

/// True when the user has an active session.
///
/// Watches [authStateChangesProvider] so it rebuilds on every auth event —
/// fixing the previous bug where the value was only read once at creation time.
@Riverpod(keepAlive: true)
bool isAuthenticated(IsAuthenticatedRef ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull?.session != null;
}

/// The currently signed-in [User], or null when signed out.
@Riverpod(keepAlive: true)
User? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull?.session?.user;
}

/// The [AuthRepository] used by all sign-in features.
@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) =>
    SupabaseAuthRepository();
