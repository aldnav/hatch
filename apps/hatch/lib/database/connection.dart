import 'package:drift/drift.dart';

import 'package:hatch/database/connection_native.dart'
    if (dart.library.html) 'package:hatch/database/connection_web.dart';

/// Opens a platform-appropriate [QueryExecutor].
/// - Mobile/Desktop: NativeDatabase via sqlite3_flutter_libs
/// - Web: WebDatabase via sql.js
Future<QueryExecutor> openConnection() => connectToDatabase();
