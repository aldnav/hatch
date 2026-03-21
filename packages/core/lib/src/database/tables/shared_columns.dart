import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Mixin that adds the four mandatory columns every Hatch table must have:
/// - [id]        — UUID primary key, client-generated.
/// - [createdAt] — Row creation timestamp.
/// - [updatedAt] — Row last-modified timestamp.
/// - [hlc]       — Hybrid Logical Clock string for CRDT-based sync
///                 (format: "<ISO-8601>-<counter>-<node-id>").
mixin TimestampedTable on Table {
  // Uses inline Uuid() so the generated part file only references the public
  // Uuid class, avoiding private-identifier scoping issues across libraries.
  TextColumn get id =>
      text().clientDefault(() => const Uuid().v4()).named('id')();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();

  /// Hybrid Logical Clock timestamp used by the sync engine.
  TextColumn get hlc => text().withDefault(const Constant('')).named('hlc')();

  @override
  Set<Column> get primaryKey => {id};
}
