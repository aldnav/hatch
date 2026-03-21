import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hatch/router/router.dart';
import 'package:ui/ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.goNamed(Routes.settings),
          ),
        ],
      ),
      // TODO(M3): replace with real trip list from Riverpod + Drift
      body: EmptyState(
        message: 'No trips yet.\nTap + to plan your first adventure.',
        icon: Icons.map_outlined,
        action: FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('New Trip'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
