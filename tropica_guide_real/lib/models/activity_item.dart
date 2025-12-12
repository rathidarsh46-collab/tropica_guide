import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityItem {
  final String id;
  final String title;
  final String? note;
  final String? timeOfDay; // simple string like "09:30"
  final int dayIndex;      // 0..N-1
  final int orderIndex;    // ordering within the day
  final String createdBy;

  // Optional fields from OpenTripMap
  final String? apiPlaceId;
  final double? lat;
  final double? lon;

  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityItem({
    required this.id,
    required this.title,
    required this.dayIndex,
    required this.orderIndex,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.timeOfDay,
    this.apiPlaceId,
    this.lat,
    this.lon,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'note': note,
      'timeOfDay': timeOfDay,
      'dayIndex': dayIndex,
      'orderIndex': orderIndex,
      'createdBy': createdBy,
      'apiPlaceId': apiPlaceId,
      'lat': lat,
      'lon': lon,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static ActivityItem fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ActivityItem(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      note: data['note'] as String?,
      timeOfDay: data['timeOfDay'] as String?,
      dayIndex: (data['dayIndex'] ?? 0) as int,
      orderIndex: (data['orderIndex'] ?? 0) as int,
      createdBy: (data['createdBy'] ?? '') as String,
      apiPlaceId: data['apiPlaceId'] as String?,
      lat: (data['lat'] as num?)?.toDouble(),
      lon: (data['lon'] as num?)?.toDouble(),
      createdAt: ((data['createdAt'] as Timestamp?)?.toDate()) ?? DateTime.now(),
      updatedAt: ((data['updatedAt'] as Timestamp?)?.toDate()) ?? DateTime.now(),
    );
  }
}
