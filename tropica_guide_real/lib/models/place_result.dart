class PlaceResult {
  final String id;
  final String name;
  final double lat;
  final double lon;

  PlaceResult({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
  });

  /// SAFE parser — returns null if invalid
  static PlaceResult? tryFromJson(Map<String, dynamic> json) {
    final point = json['point'];
    if (point == null) return null;

    final lat = point['lat'];
    final lon = point['lon'];

    if (lat == null || lon == null) return null;

    final name = json['name'];
    if (name == null || name.toString().trim().isEmpty) return null;

    return PlaceResult(
      id: json['xid'] ?? '',
      name: name.toString(),
      lat: (lat as num).toDouble(),
      lon: (lon as num).toDouble(),
    );
  }
}
