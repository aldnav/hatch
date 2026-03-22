import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  group('UsersDao', () {
    test('getUserById returns null for non-existent id', () async {
      final result = await db.usersDao.getUserById('no-such-id');
      expect(result, isNull);
    });

    test('upsertUser inserts and getUserById returns it', () async {
      await db.usersDao.upsertUser(
        id: 'user-1',
        email: 'alice@example.com',
        name: 'Alice',
      );

      final user = await db.usersDao.getUserById('user-1');
      expect(user, isNotNull);
      expect(user!.id, equals('user-1'));
      expect(user.email, equals('alice@example.com'));
      expect(user.name, equals('Alice'));
    });

    test('upsertUser updates an existing row', () async {
      await db.usersDao.upsertUser(
        id: 'user-1',
        email: 'alice@example.com',
        name: 'Alice',
      );

      await db.usersDao.upsertUser(
        id: 'user-1',
        email: 'alice@example.com',
        name: 'Alice Updated',
        avatarUrl: 'https://example.com/avatar.png',
      );

      final user = await db.usersDao.getUserById('user-1');
      expect(user, isNotNull);
      expect(user!.name, equals('Alice Updated'));
      expect(user.avatarUrl, equals('https://example.com/avatar.png'));
    });

    test('name defaults to empty string when null is passed', () async {
      await db.usersDao.upsertUser(
        id: 'user-2',
        email: 'bob@example.com',
      );

      final user = await db.usersDao.getUserById('user-2');
      expect(user, isNotNull);
      expect(user!.name, equals(''));
    });

    test('watchUserById emits updated value after upsert', () async {
      final stream = db.usersDao.watchUserById('user-3');

      // Collect values emitted during the test.
      final values = <User?>[];
      final subscription = stream.listen(values.add);

      // Initially no row exists — first emission should be null.
      await Future<void>.delayed(Duration.zero);
      expect(values, contains(null));

      await db.usersDao.upsertUser(
        id: 'user-3',
        email: 'carol@example.com',
        name: 'Carol',
      );
      await Future<void>.delayed(Duration.zero);

      expect(values.last, isNotNull);
      expect(values.last!.name, equals('Carol'));

      await subscription.cancel();
    });
  });
}
