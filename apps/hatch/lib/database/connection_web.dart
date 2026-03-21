import 'package:drift/drift.dart';
import 'package:drift/web.dart';

Future<QueryExecutor> connectToDatabase() async {
  return WebDatabase('hatch');
}
