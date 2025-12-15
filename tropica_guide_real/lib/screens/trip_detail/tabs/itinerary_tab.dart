import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/trip.dart';
import '../../../models/activity_item.dart';
import '../../../services/trips_service.dart';

class ItineraryTab extends StatefulWidget {
  final Trip trip;

  const ItineraryTab({super.key, required this.trip});

  @override
  State<ItineraryTab> createState() => _ItineraryTabState();
}

class _ItineraryTabState extends State<ItineraryTab> {
  int _selectedDayIndex = 0;

  // Total days in the trip (inclusive)
  int get _totalDays =>
      widget.trip.endDate.difference(widget.trip.startDate).inDays + 1;

  // Simple helper for UI label
  String _dayLabel(int dayIndex) => 'Day ${dayIndex + 1}';

  @override
  Widget build(BuildContext context) {
    final tripsService = context.read<TripsService>();

    return Column(
      children: [
        // ----------------------------------------------------
        // Day selector (horizontal chips)
        // ----------------------------------------------------
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _totalDays,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedDayIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: ChoiceChip(
                  label: Text(_dayLabel(index)),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedDayIndex = index;
                    });
                  },
                ),
              );
            },
          ),
        ),

        const Divider(height: 1),

        // ----------------------------------------------------
        // Activities list for selected day (real-time stream)
        // ----------------------------------------------------
        Expanded(
          child: StreamBuilder<List<ActivityItem>>(
            stream: tripsService.streamActivitiesForDay(
              widget.trip.id,
              _selectedDayIndex,
            ),
            builder: (context, snapshot) {
              // Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Error
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load itinerary.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final activities = snapshot.data ?? [];

              // Empty state
              if (activities.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No activities for ${_dayLabel(_selectedDayIndex)} yet.\n'
                      'Add activities to build your itinerary.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // Reorderable list (drag & drop)
              return ReorderableListView.builder(
                itemCount: activities.length,
                onReorder: (oldIndex, newIndex) {
                  // ReorderableListView gives a "post-removal" index,
                  // so adjust when dragging down.
                  if (newIndex > oldIndex) newIndex -= 1;

                  // Create a new list in the new order
                  final reordered = List<ActivityItem>.from(activities);
                  final moved = reordered.removeAt(oldIndex);
                  reordered.insert(newIndex, moved);

                  // Persist order to Firestore (batch update in TripsService)
                  tripsService.reorderActivities(
                    tripId: widget.trip.id,
                    reordered: reordered,
                  );
                },
                itemBuilder: (context, index) {
                  final activity = activities[index];

                  return ListTile(
                    key: ValueKey(activity.id),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(activity.title),
                    subtitle: _subtitleFor(activity),
                    trailing: IconButton(
                      tooltip: 'Delete activity',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        tripsService.deleteActivity(
                          widget.trip.id,
                          activity.id,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Build a clean subtitle based on optional fields (time + note)
  Widget? _subtitleFor(ActivityItem activity) {
    final parts = <String>[];

    if (activity.timeOfDay != null && activity.timeOfDay!.trim().isNotEmpty) {
      parts.add(activity.timeOfDay!.trim());
    }

    if (activity.note != null && activity.note!.trim().isNotEmpty) {
      parts.add(activity.note!.trim());
    }

    if (parts.isEmpty) return null;

    return Text(parts.join(' • '));
  }
}
