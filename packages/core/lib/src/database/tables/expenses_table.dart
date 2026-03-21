import 'package:drift/drift.dart';

import 'shared_columns.dart';
import 'activities_table.dart';
import 'trips_table.dart';

class Expenses extends Table with TimestampedTable {
  TextColumn get tripId => text().references(Trips, #id).named('trip_id')();
  TextColumn get activityId =>
      text().references(Activities, #id).nullable().named('activity_id')();
  TextColumn get currency =>
      text().withDefault(const Constant('USD')).named('currency')();
  RealColumn get amount => real().named('amount')();

  /// 'food' | 'transport' | 'accommodation' | 'activities' | 'shopping' | 'other'
  TextColumn get category => text().nullable().named('category')();
  TextColumn get description => text().nullable().named('description')();

  @override
  String get tableName => 'expenses';
}
