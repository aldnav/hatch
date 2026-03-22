import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables/users_table.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  /// Returns the user row for [id], or null if not yet created.
  Future<User?> getUserById(String id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  /// Watches the user row for [id], emitting whenever it changes.
  Stream<User?> watchUserById(String id) =>
      (select(users)..where((u) => u.id.equals(id))).watchSingleOrNull();

  /// Inserts or updates the user row. [name] defaults to empty string if null.
  Future<void> upsertUser({
    required String id,
    required String email,
    String? name,
    String? avatarUrl,
  }) =>
      into(users).insertOnConflictUpdate(
        UsersCompanion.insert(
          id: Value(id),
          email: email,
          name: name ?? '',
          avatarUrl: Value(avatarUrl),
        ),
      );
}
