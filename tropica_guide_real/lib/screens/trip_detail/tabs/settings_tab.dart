import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/trip.dart';
import '../../../services/trips_service.dart';
import '../../trips/trip_form_screen.dart';

class SettingsTab extends StatelessWidget {
  final Trip trip;

  const SettingsTab({super.key, required this.trip});

  Future<void> _confirmDelete(BuildContext context) async {
    final service = context.read<TripsService>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete trip?'),
        content: const Text(
          'This will remove the trip from your active list.\n'
          'For this project we use a “soft delete”.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (ok != true) return;

    // Soft delete keeps data for demo recovery if needed
    await service.softDeleteTrip(trip.id);

    if (!context.mounted) return;
    Navigator.pop(context); // Back to MyTrips
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Trip Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Edit trip
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Edit trip details'),
          subtitle: const Text('Name, destination, dates, collaborators'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TripFormScreen(existingTrip: trip)),
            );
          },
        ),

        const Divider(),

        // Collaborators (for now, display emails)
        ListTile(
          leading: const Icon(Icons.group),
          title: const Text('Collaborators'),
          subtitle: Text(
            trip.collaboratorEmails.isEmpty
                ? 'No collaborators added'
                : trip.collaboratorEmails.join(', '),
          ),
        ),

        const Divider(),

        // Delete trip
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Delete trip', style: TextStyle(color: Colors.red)),
          subtitle: const Text('Soft delete (recommended for this project)'),
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }
}
