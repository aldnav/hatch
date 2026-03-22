/// Core package — business logic, Drift database, and Riverpod providers.
library core;

export 'src/database/app_database.dart';
export 'src/database/users_dao.dart';
export 'src/database/tables/activities_table.dart';
export 'src/database/tables/attachments_table.dart';
export 'src/database/tables/collaborators_table.dart';
export 'src/database/tables/expenses_table.dart';
export 'src/database/tables/flights_table.dart';
export 'src/database/tables/hotels_table.dart';
export 'src/database/tables/notes_table.dart';
export 'src/database/tables/places_table.dart';
export 'src/database/tables/shared_columns.dart';
export 'src/database/tables/sync_log_table.dart';
export 'src/database/tables/trip_days_table.dart';
export 'src/database/tables/trips_table.dart';
export 'src/database/tables/users_table.dart';
export 'src/providers/database_provider.dart';
