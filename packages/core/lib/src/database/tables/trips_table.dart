import 'package:drift/drift.dart';

import 'shared_columns.dart';
import 'users_table.dart';

class Trips extends Table with TimestampedTable {
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get title => text().named('title')();
  TextColumn get destination => text().named('destination')();
  DateTimeColumn get startDate => dateTime().nullable().named('start_date')();
  DateTimeColumn get endDate => dateTime().nullable().named('end_date')();

  /// 'draft' | 'active' | 'completed' | 'archived'
  TextColumn get status =>
      text().withDefault(const Constant('draft')).named('status')();

  @override
  String get tableName => 'trips';
}
