import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../utils/date_format.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Visual hint if trip is shared vs owned
    final isShared = trip.collaboratorIds.isNotEmpty || trip.collaboratorEmails.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + edit button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit trip',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                '${trip.destinationCity}, ${trip.destinationCountry}',
                style: TextStyle(color: Colors.grey.shade700),
              ),

              const SizedBox(height: 8),

              // Dates
              Text(
                '${DateFormatters.mdy(trip.startDate)} → ${DateFormatters.mdy(trip.endDate)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),

              const SizedBox(height: 10),

              // Shared label (simple, clear)
              if (isShared)
                Row(
                  children: [
                    const Icon(Icons.group, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Shared trip',
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}