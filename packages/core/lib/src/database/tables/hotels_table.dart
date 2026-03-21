import 'package:drift/drift.dart';

import 'shared_columns.dart';
import 'trips_table.dart';

class Hotels extends Table with TimestampedTable {
  TextColumn get tripId => text().references(Trips, #id).named('trip_id')();
  TextColumn get name => text().named('name')();
  TextColumn get address => text().nullable().named('address')();
  DateTimeColumn get checkIn => dateTime().nullable().named('check_in')();
  DateTimeColumn get checkOut => dateTime().nullable().named('check_out')();
  TextColumn get confirmationNumber =>
      text().nullable().named('confirmation_number')();

  @override
  String get tableName => 'hotels';
}
