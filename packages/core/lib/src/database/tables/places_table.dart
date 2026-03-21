import 'package:drift/drift.dart';

import 'shared_columns.dart';

class Places extends Table with TimestampedTable {
  TextColumn get name => text().named('name')();
  TextColumn get address => text().nullable().named('address')();
  RealColumn get latitude => real().nullable().named('latitude')();
  RealColumn get longitude => real().nullable().named('longitude')();
  TextColumn get category => text().nullable().named('category')();

  /// External identifier, e.g. a Google Places ID or OSM node ID.
  TextColumn get externalId => text().nullable().named('external_id')();

  @override
  String get tableName => 'places';
}
