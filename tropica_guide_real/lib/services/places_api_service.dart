import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/place_result.dart';

class PlacesApiService {
  // 🔐 Replace with your real key
  static const String _apiKey = 'YOUR_OPEN_TRIP_MAP_API_KEY';

  static const String _baseUrl = 'https://api.opentripmap.com/0.1/en/places';

  /// Step 1: Convert city name -> coordinates
  Future<Map<String, double>> _getCityCoordinates(String city) async {
    final url = Uri.parse(
      '$_baseUrl/geoname?name=$city&apikey=$_apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to geocode city');
    }

    final data = jsonDecode(response.body);
    return {
      'lat': (data['lat'] as num).toDouble(),
      'lon': (data['lon'] as num).toDouble(),
    };
  }

  /// Step 2: Fetch places near that city
  Future<List<PlaceResult>> searchPlaces({
    required String city,
  }) async {
    final coords = await _getCityCoordinates(city);

    final url = Uri.parse(
      '$_baseUrl/radius'
      '?radius=5000'
      '&lat=${coords['lat']}'
      '&lon=${coords['lon']}'
      '&limit=20'
      '&apikey=$_apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch places');
    }

    final List data = jsonDecode(response.body);

    return data
        .where((item) => item['name'] != null && item['name'] != '')
        .map((item) => PlaceResult.fromJson(item))
        .toList();
  }
}