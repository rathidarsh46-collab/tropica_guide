import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/trip.dart';
import '../../../models/checklist_item.dart';
import '../../../services/trips_service.dart';

class ChecklistTab extends StatefulWidget {
  final Trip trip;

  const ChecklistTab({super.key, required this.trip});

  @override
  State<ChecklistTab> createState() => _ChecklistTabState();
}

class _ChecklistTabState extends State<ChecklistTab> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // TripsService already knows current user via FirebaseAuth (same pattern as Packing)
    await context.read<TripsService>().addChecklistItem(widget.trip.id, text);

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tripsService = context.read<TripsService>();

    return Column(
      children: [
        // -----------------------
        // Add item input row
        // -----------------------
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Add checklist item',
                    hintText: 'e.g., Book flights, Confirm hotel',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Add',
                icon: const Icon(Icons.add_circle),
                onPressed: _addItem,
              ),
            ],
          ),
        ),

        // -----------------------
        // Real-time list
        // -----------------------
        Expanded(
          child: StreamBuilder<List<ChecklistItem>>(
            stream: tripsService.streamChecklist(widget.trip.id),
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
                      'Could not load checklist.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final items = snapshot.data ?? [];

              // Empty
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No checklist items yet.\nAdd your first task above.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = items[i];

                  return ListTile(
                    leading: Checkbox(
                      value: item.isCompleted,
                      onChanged: (_) {
                        tripsService.toggleChecklistItem(widget.trip.id, item);
                      },
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        tripsService.deleteChecklistItem(widget.trip.id, item.id);
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
}
