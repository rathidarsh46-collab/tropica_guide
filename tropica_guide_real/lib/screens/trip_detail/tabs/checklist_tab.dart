import 'package:flutter/material.dart';
import '../../../models/trip.dart';

class ChecklistTab extends StatelessWidget {
  final Trip trip;

  const ChecklistTab({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    // Placeholder; Shrey will implement real-time checklist soon.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Trip checklist will appear here.\n'
          'Next: real-time Firestore StreamBuilder + add/toggle/delete.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
