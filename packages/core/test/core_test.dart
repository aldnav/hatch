import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:core/core.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('database opens and all tables exist', () async {
    // Inserting a user exercises schema creation.
    await db.into(db.users).insert(
          UsersCompanion.insert(
            email: 'test@example.com',
            name: 'Test User',
          ),
        );

    final users = await db.select(db.users).get();
    expect(users, hasLength(1));
    expect(users.first.email, 'test@example.com');
  });

  test('trip can be created and linked to a user', () async {
    await db.into(db.users).insert(
          UsersCompanion.insert(
            email: 'traveller@example.com',
            name: 'Traveller',
          ),
        );

    final user = await (db.select(db.users)
          ..where((u) => u.email.equals('traveller@example.com')))
        .getSingle();

    await db.into(db.trips).insert(
          TripsCompanion.insert(
            userId: user.id,
            title: 'Tokyo 2025',
            destination: 'Tokyo, Japan',
          ),
        );

    final trips = await db.select(db.trips).get();
    expect(trips, hasLength(1));
    expect(trips.first.title, 'Tokyo 2025');
  });
}
