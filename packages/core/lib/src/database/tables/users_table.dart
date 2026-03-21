import 'package:drift/drift.dart';

import 'shared_columns.dart';

class Users extends Table with TimestampedTable {
  TextColumn get email => text().unique().named('email')();
  TextColumn get name => text().named('name')();
  TextColumn get avatarUrl => text().nullable().named('avatar_url')();

  @override
  String get tableName => 'users';
}
