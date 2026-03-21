import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hatch/app.dart';
import 'package:hatch/database/connection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'http://localhost:8000',
    ),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final executor = await openConnection();
  final db = AppDatabase(executor);

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const HatchApp(),
    ),
  );
}
