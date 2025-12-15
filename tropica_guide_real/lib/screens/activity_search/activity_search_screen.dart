import 'package:flutter/material.dart';

import '../../models/place_result.dart';
import '../../services/places_api_service.dart';

class ActivitySearchScreen extends StatefulWidget {
  final String city;

  const ActivitySearchScreen({
    super.key,
    required this.city,
  });

  @override
  State<ActivitySearchScreen> createState() => _ActivitySearchScreenState();
}

class _ActivitySearchScreenState extends State<ActivitySearchScreen> {
  final _api = PlacesApiService();
  late Future<List<PlaceResult>> _results;

  @override
  void initState() {
    super.initState();
    _results = _api.searchPlaces(city: widget.city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Activities')),
      body: FutureBuilder<List<PlaceResult>>(
        future: _results,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading places.\nTry manual entry instead.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final places = snapshot.data!;

          if (places.isEmpty) {
            return const Center(child: Text('No places found.'));
          }

          return ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];

              return ListTile(
                title: Text(place.name),
                trailing: const Icon(Icons.add),
                onTap: () {
                  Navigator.pop(context, place);
                },
              );
            },
          );
        },
      ),
    );
  }
}