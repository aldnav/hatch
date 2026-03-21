import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  testWidgets('EmptyState renders message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(message: 'No trips yet'),
        ),
      ),
    );

    expect(find.text('No trips yet'), findsOneWidget);
  });
}
