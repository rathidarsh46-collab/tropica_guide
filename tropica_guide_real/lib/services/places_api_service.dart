import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/place_result.dart';

class PlacesApiService {
  static const _apiKey = 'YOUR_OPENTRIPMAP_API_KEY';
  static const _host = 'api.opentripmap.com';

  /// Hard-coded cities (reliable)
  static const Map<String, Map<String, double>> _cityCoords = {
    'madrid': {'lat': 40.4168, 'lon': -3.7038},
  };

  Future<List<PlaceResult>> searchPlaces({
  required String city,
}) async {
  final key = city
      .toLowerCase()
      .replaceAll(',', '')
      .replaceAll('Spain', '')
      .trim();

  if (!_cityCoords.containsKey(key)) {
    return [];
  }


    final coords = _cityCoords[key]!;

    final url = Uri.https(
      _host,
      '/0.1/en/places/radius',
      {
        'radius': '5000',
        'lat': coords['lat']!.toString(),
        'lon': coords['lon']!.toString(),
        'limit': '30',
        'apikey': _apiKey,
      },
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return [];
      }

      final List raw = jsonDecode(response.body);

      final results = <PlaceResult>[];

      for (final item in raw) {
        final place = PlaceResult.tryFromJson(item);
        if (place != null) {
          results.add(place);
        }
      }

      return results;
    } catch (_) {
      return [];
    }
  }
}
