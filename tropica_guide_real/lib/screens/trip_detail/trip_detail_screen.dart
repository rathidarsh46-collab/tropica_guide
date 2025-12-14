import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trip.dart';
import '../../services/trips_service.dart';
import 'tabs/overview_tab.dart';
import 'tabs/itinerary_tab.dart';
import 'tabs/packing_tab.dart';
import 'tabs/checklist_tab.dart';
import 'tabs/settings_tab.dart';

class TripDetailScreen extends StatelessWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final service = context.read<TripsService>();

    // Stream the trip doc so changes (edit/delete) update UI instantly
    return StreamBuilder<Trip>(
      stream: service.streamTrip(tripId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Error loading trip: ${snap.error}')));
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: Text('Trip not found')));
        }

        final trip = snap.data!;

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            appBar: AppBar(
              title: Text(trip.name),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Itinerary'),
                  Tab(text: 'Packing'),
                  Tab(text: 'Checklist'),
                  Tab(text: 'Settings'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                OverviewTab(trip: trip),
                ItineraryTab(trip: trip),
                PackingTab(trip: trip),
                ChecklistTab(trip: trip),
                SettingsTab(trip: trip),
              ],
            ),
          ),
        );
      },
    );
  }
}
