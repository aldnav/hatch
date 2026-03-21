import 'package:drift/drift.dart';

import 'shared_columns.dart';
import 'trips_table.dart';

class Flights extends Table with TimestampedTable {
  TextColumn get tripId => text().references(Trips, #id).named('trip_id')();
  TextColumn get flightNumber => text().nullable().named('flight_number')();
  TextColumn get airline => text().nullable().named('airline')();
  TextColumn get origin => text().named('origin')();
  TextColumn get destination => text().named('destination')();
  DateTimeColumn get departsAt => dateTime().named('departs_at')();
  DateTimeColumn get arrivesAt => dateTime().named('arrives_at')();
  TextColumn get bookingRef => text().nullable().named('booking_ref')();

  /// 'economy' | 'premium_economy' | 'business' | 'first'
  TextColumn get seatClass => text().nullable().named('seat_class')();

  @override
  String get tableName => 'flights';
}
