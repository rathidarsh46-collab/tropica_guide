import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/trip.dart';
import '../../../models/activity_item.dart';
import '../../../models/place_result.dart';
import '../../../services/trips_service.dart';
import '../activity_search/activity_search_screen.dart';

class ItineraryTab extends StatefulWidget {
  final Trip trip;

  const ItineraryTab({super.key, required this.trip});

  @override
  State<ItineraryTab> createState() => _ItineraryTabState();
}

class _ItineraryTabState extends State<ItineraryTab> {
  int _selectedDayIndex = 0;

  int get _totalDays =>
      widget.trip.endDate.difference(widget.trip.startDate).inDays + 1;

  String _dayLabel(int dayIndex) => 'Day ${dayIndex + 1}';

  @override
  Widget build(BuildContext context) {
    final tripsService = context.read<TripsService>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add activity',
        child: const Icon(Icons.add),
        onPressed: () => _showAddOptions(context),
      ),
      body: Column(
        children: [
          // ---------------- Day selector ----------------
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _totalDays,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: ChoiceChip(
                    label: Text(_dayLabel(index)),
                    selected: index == _selectedDayIndex,
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

          // ---------------- Activities ----------------
          Expanded(
            child: StreamBuilder<List<ActivityItem>>(
              stream: tripsService.streamActivitiesForDay(
                widget.trip.id,
                _selectedDayIndex,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading itinerary: ${snapshot.error}'),
                  );
                }

                final activities = snapshot.data ?? [];

                if (activities.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No activities for ${_dayLabel(_selectedDayIndex)} yet.\n'
                        'Tap + to add one.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ReorderableListView.builder(
                  itemCount: activities.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;

                    final reordered =
                        List<ActivityItem>.from(activities);
                    final moved = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, moved);

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
      ),
    );
  }

  // ================= ADD ACTIVITY OPTIONS =================

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search activities'),
                subtitle: const Text('Find places using OpenTripMap'),
                onTap: () async {
                  Navigator.pop(context);
                  await _searchActivities(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Add manually'),
                subtitle: const Text('Create your own activity'),
                onTap: () {
                  Navigator.pop(context);
                  _showManualAddSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= SEARCH FLOW =================

  Future<void> _searchActivities(BuildContext context) async {
    final PlaceResult? place = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivitySearchScreen(
          city: widget.trip.destinationCity,
        ),
      ),
    );

    if (place == null) return;

    await context.read<TripsService>().addActivity(
          tripId: widget.trip.id,
          title: place.name,
          dayIndex: _selectedDayIndex,
          apiPlaceId: place.id,
          lat: place.lat,
          lon: place.lon,
        );
  }

  // ================= MANUAL FLOW =================

  void _showManualAddSheet(BuildContext context) {
    final titleController = TextEditingController();
    final timeController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Activity (${_dayLabel(_selectedDayIndex)})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Activity title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time (optional)',
                  hintText: 'e.g., 09:30',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                child: const Text('Add Activity'),
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;

                  await context.read<TripsService>().addActivity(
                        tripId: widget.trip.id,
                        title: title,
                        dayIndex: _selectedDayIndex,
                        timeOfDay:
                            timeController.text.trim().isEmpty
                                ? null
                                : timeController.text.trim(),
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= HELPERS =================

  Widget? _subtitleFor(ActivityItem activity) {
    final parts = <String>[];

    if (activity.timeOfDay != null &&
        activity.timeOfDay!.trim().isNotEmpty) {
      parts.add(activity.timeOfDay!.trim());
    }

    if (activity.note != null && activity.note!.trim().isNotEmpty) {
      parts.add(activity.note!.trim());
    }

    if (parts.isEmpty) return null;
    return Text(parts.join(' • '));
  }
}
