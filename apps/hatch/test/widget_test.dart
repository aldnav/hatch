import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatch/app.dart';

void main() {
  testWidgets('app renders without crashing', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const HatchApp(),
      ),
    );

    // App starts on auth screen (no active session in test).
    expect(find.text('Hatch'), findsWidgets);
  });
}
