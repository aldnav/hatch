import 'package:core/core.dart';
import 'package:hatch/providers/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile_provider.g.dart';

/// Watches the signed-in user's profile row in the local Drift database.
/// Emits null when no user is signed in or the row does not yet exist.
@Riverpod(keepAlive: true)
Stream<User?> userProfile(UserProfileRef ref) {
  final authUser = ref.watch(currentUserProvider);
  if (authUser == null) return Stream.value(null);
  final db = ref.watch(appDatabaseProvider);
  return db.usersDao.watchUserById(authUser.id);
}
