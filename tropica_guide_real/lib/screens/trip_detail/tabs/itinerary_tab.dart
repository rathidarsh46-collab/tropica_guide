import 'package:flutter/material.dart';
import '../../../models/trip.dart';

class ItineraryTab extends StatelessWidget {
  final Trip trip;

  const ItineraryTab({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    // Placeholder for now; Darsh will implement drag-and-drop + activities next.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Itinerary will appear here.\n'
          'Next: day selector + reorderable activities + add activity.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
