import 'package:flutter/material.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip'),
      ),
      // TODO(M3): load trip from Drift via tripId and build day/activity list
      body: Center(
        child: Text('Trip $tripId'),
      ),
    );
  }
}
