import 'package:flutter/material.dart';
import '../../../models/trip.dart';

class PackingTab extends StatelessWidget {
  final Trip trip;

  const PackingTab({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    // Placeholder; Shrey will implement real-time packing list soon.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Packing list will appear here.\n'
          'Next: real-time Firestore StreamBuilder + add/toggle/delete.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
