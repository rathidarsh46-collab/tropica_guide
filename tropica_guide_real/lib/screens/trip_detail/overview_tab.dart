import 'package:flutter/material.dart';

import '../../../models/trip.dart';
import '../../../utils/date_format.dart';

class OverviewTab extends StatelessWidget {
  final Trip trip;

  const OverviewTab({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Trip summary
        Text(
          '${trip.destinationCity}, ${trip.destinationCountry}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          '${DateFormatters.mdy(trip.startDate)} → ${DateFormatters.mdy(trip.endDate)}',
          style: TextStyle(color: Colors.grey.shade700),
        ),

        const SizedBox(height: 16),

        // Placeholder weather area (Darsh will fill this with real API later)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weather', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'Weather data will appear here.\n'
                  'This will be powered by the Weather API integration.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Quick explanation for demo / rubric (optional)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How collaboration works', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'Trips are stored in Firestore, and collaborators can view/update\n'
                  'packing lists, checklists, and itinerary activities in real time.\n'
                  'Conflict strategy: last write wins.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
