import 'package:drift/drift.dart';

import 'shared_columns.dart';
import 'trips_table.dart';

class Attachments extends Table with TimestampedTable {
  TextColumn get tripId => text().references(Trips, #id).named('trip_id')();
  TextColumn get mimeType => text().named('mime_type')();
  TextColumn get fileName => text().named('file_name')();

  /// Path in Supabase Storage (or cloud provider). Binary is NOT stored locally.
  TextColumn get storagePath => text().named('storage_path')();
  IntColumn get sizeBytes => integer().nullable().named('size_bytes')();

  @override
  String get tableName => 'attachments';
}
