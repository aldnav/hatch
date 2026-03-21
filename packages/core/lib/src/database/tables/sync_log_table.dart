import 'package:drift/drift.dart';

import 'shared_columns.dart';

class SyncLog extends Table with TimestampedTable {
  /// Name of the table this log entry refers to.
  TextColumn get entityTable => text().named('entity_table')();

  /// UUID of the row that was changed.
  TextColumn get entityId => text().named('entity_id')();

  /// 'insert' | 'update' | 'delete'
  TextColumn get operation => text().named('operation')();

  /// JSON-encoded diff payload for the sync engine.
  TextColumn get payload => text().nullable().named('payload')();

  BoolColumn get synced =>
      boolean().withDefault(const Constant(false)).named('synced')();
  DateTimeColumn get syncedAt => dateTime().nullable().named('synced_at')();

  @override
  String get tableName => 'sync_log';
}
