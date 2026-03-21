import 'package:drift/drift.dart';

import 'shared_columns.dart';
import 'trips_table.dart';

class TripDays extends Table with TimestampedTable {
  TextColumn get tripId => text().references(Trips, #id).named('trip_id')();
  IntColumn get dayNumber => integer().named('day_number')();
  DateTimeColumn get date => dateTime().nullable().named('date')();
  TextColumn get notes => text().nullable().named('notes')();

  @override
  String get tableName => 'trip_days';
}
