import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'tables/activities_table.dart';
import 'tables/attachments_table.dart';
import 'tables/collaborators_table.dart';
import 'tables/expenses_table.dart';
import 'tables/flights_table.dart';
import 'tables/hotels_table.dart';
import 'tables/notes_table.dart';
import 'tables/places_table.dart';
import 'tables/sync_log_table.dart';
import 'tables/trip_days_table.dart';
import 'tables/trips_table.dart';
import 'tables/users_table.dart';

part 'app_database.g.dart';

// uuid is imported so the generated part file can reference Uuid directly.

@DriftDatabase(
  tables: [
    Users,
    Trips,
    TripDays,
    Activities,
    Places,
    Flights,
    Hotels,
    Notes,
    Expenses,
    Attachments,
    Collaborators,
    SyncLog,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Future migrations added here as schemaVersion increments.
        },
      );
}
