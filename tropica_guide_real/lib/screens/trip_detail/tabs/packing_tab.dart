import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/trip.dart';
import '../../../models/packing_item.dart';
import '../../../services/trips_service.dart';

class PackingTab extends StatefulWidget {
  final Trip trip;

  const PackingTab({super.key, required this.trip});

  @override
  State<PackingTab> createState() => _PackingTabState();
}

class _PackingTabState extends State<PackingTab> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Uses TripsService which already knows current user via FirebaseAuth
    await context.read<TripsService>().addPackingItem(widget.trip.id, text);

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
                    labelText: 'Add packing item',
                    hintText: 'e.g., Passport, Sunscreen, Charger',
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
          child: StreamBuilder<List<PackingItem>>(
            stream: tripsService.streamPacking(widget.trip.id),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Error state
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load packing list.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final items = snapshot.data ?? [];

              // Empty state
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No items yet.\nAdd your first item above.',
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
                      value: item.isChecked,
                      onChanged: (_) {
                        tripsService.togglePackingItem(widget.trip.id, item);
                      },
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        decoration: item.isChecked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    // Optional: show who added it (useful for collaboration demo)
                    subtitle: item.addedBy.isNotEmpty
                        ? Text('Added by: ${item.addedBy}')
                        : null,
                    trailing: IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        tripsService.deletePackingItem(widget.trip.id, item.id);
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
