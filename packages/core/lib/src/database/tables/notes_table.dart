import 'package:drift/drift.dart';

import 'shared_columns.dart';
import 'trips_table.dart';

class Notes extends Table with TimestampedTable {
  TextColumn get tripId => text().references(Trips, #id).named('trip_id')();
  TextColumn get content => text().named('content')();

  /// 'packing' | 'general' | 'tips' | 'emergency'
  TextColumn get category => text().nullable().named('category')();

  @override
  String get tableName => 'notes';
}
