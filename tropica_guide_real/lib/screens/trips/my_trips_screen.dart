import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trip.dart';
import '../../services/auth_service.dart';
import '../../services/trips_service.dart';
import '../../widgets/trip_card.dart';
import '../../routes.dart';
import 'trip_form_screen.dart';
import '../trip_detail/trip_detail_screen.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  // Merge owned + shared trips, remove duplicates, sort by updatedAt desc
  List<Trip> _mergeTrips(List<Trip> owned, List<Trip> shared) {
    final byId = <String, Trip>{};

    for (final t in owned) {
      byId[t.id] = t;
    }
    for (final t in shared) {
      // If same trip appears in both (rare), keep the one with newer updatedAt
      final existing = byId[t.id];
      if (existing == null) {
        byId[t.id] = t;
      } else {
        byId[t.id] = (t.updatedAt.isAfter(existing.updatedAt)) ? t : existing;
      }
    }

    final merged = byId.values.toList();
    merged.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final tripsService = context.read<TripsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              // Keep logout logic centralized in AuthService
              await context.read<AuthService>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, Routes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      // FAB to create a new trip
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Trip',
        onPressed: () {
          // Use MaterialPageRoute for screens requiring args / custom constructors
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TripFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<List<Trip>>(
        // Real-time owned trips
        stream: tripsService.streamOwnedTrips(),
        builder: (context, ownedSnap) {
          if (ownedSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ownedSnap.hasError) {
            return Center(child: Text('Error loading owned trips: ${ownedSnap.error}'));
          }

          final owned = ownedSnap.data ?? const [];

          return StreamBuilder<List<Trip>>(
            // Real-time shared trips
            stream: tripsService.streamSharedTrips(),
            builder: (context, sharedSnap) {
              if (sharedSnap.connectionState == ConnectionState.waiting) {
                // Owned may have loaded already, but shared still loading
                return const Center(child: CircularProgressIndicator());
              }
              if (sharedSnap.hasError) {
                return Center(child: Text('Error loading shared trips: ${sharedSnap.error}'));
              }

              final shared = sharedSnap.data ?? const [];
              final trips = _mergeTrips(owned, shared);

              if (trips.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No trips yet.\nTap + to create your first trip.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: trips.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final trip = trips[i];

                  return TripCard(
                    trip: trip,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TripDetailScreen(tripId: trip.id),
                        ),
                      );
                    },
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TripFormScreen(existingTrip: trip),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
