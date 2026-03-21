import 'package:drift/drift.dart';

import 'shared_columns.dart';
import 'places_table.dart';
import 'trip_days_table.dart';

class Activities extends Table with TimestampedTable {
  TextColumn get tripDayId =>
      text().references(TripDays, #id).named('trip_day_id')();
  TextColumn get placeId =>
      text().references(Places, #id).nullable().named('place_id')();
  TextColumn get title => text().named('title')();

  /// 'visit' | 'meal' | 'transport' | 'accommodation' | 'other'
  TextColumn get type => text().named('type')();

  DateTimeColumn get startsAt => dateTime().nullable().named('starts_at')();
  DateTimeColumn get endsAt => dateTime().nullable().named('ends_at')();
  TextColumn get notes => text().nullable().named('notes')();

  @override
  String get tableName => 'activities';
}
