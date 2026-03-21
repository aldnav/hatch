import 'package:drift/drift.dart';

import 'shared_columns.dart';
import 'trips_table.dart';
import 'users_table.dart';

class Collaborators extends Table with TimestampedTable {
  TextColumn get tripId => text().references(Trips, #id).named('trip_id')();
  TextColumn get userId => text().references(Users, #id).named('user_id')();

  /// 'owner' | 'editor' | 'viewer'
  TextColumn get role =>
      text().withDefault(const Constant('viewer')).named('role')();

  @override
  String get tableName => 'collaborators';

  @override
  List<Set<Column>> get uniqueKeys => [
        {tripId, userId},
      ];
}
