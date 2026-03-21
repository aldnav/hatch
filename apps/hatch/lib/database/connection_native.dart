import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

Future<QueryExecutor> connectToDatabase() async {
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'hatch.db');
  return NativeDatabase(File(dbPath));
}
