class PlaceResult {
  final String id;        // OpenTripMap xid
  final String name;
  final double lat;
  final double lon;

  PlaceResult({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
  });

  /// Convert raw JSON from OpenTripMap into a Dart object
  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      id: json['xid'] as String,
      name: (json['name'] ?? 'Unknown place') as String,
      lat: (json['point']['lat'] as num).toDouble(),
      lon: (json['point']['lon'] as num).toDouble(),
    );
  }
}
