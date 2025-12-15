import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trip.dart';
import '../models/activity_item.dart';
import '../models/packing_item.dart';
import '../models/checklist_item.dart';

class TripsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Convenience getter for current user id
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Root trips collection
  CollectionReference<Map<String, dynamic>> get _trips =>
      _db.collection('trips');

  // ============================================================
  // TRIPS
  // ============================================================

  /// NOTE:
  /// Firestore does NOT support:
  ///   ownerId == uid OR collaboratorIds contains uid
  ///
  /// We intentionally expose two streams and merge in the UI.
  Stream<List<Trip>> streamMyTrips() {
    throw UnimplementedError(
      'Use streamOwnedTrips() and streamSharedTrips() and merge in UI.',
    );
  }

  Stream<List<Trip>> streamOwnedTrips() {
    return _trips
        .where('ownerId', isEqualTo: _uid)
        .where('isDeleted', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Trip.fromDoc).toList());
  }

  Stream<List<Trip>> streamSharedTrips() {
    return _trips
        .where('collaboratorIds', arrayContains: _uid)
        .where('isDeleted', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Trip.fromDoc).toList());
  }

  Future<String> createTrip({
    required String name,
    required String destinationCity,
    required String destinationCountry,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> collaboratorEmails,
  }) async {
    final now = DateTime.now();

    final doc = await _trips.add({
      'ownerId': _uid,
      'name': name,
      'destinationCity': destinationCity,
      'destinationCountry': destinationCountry,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'collaboratorEmails': collaboratorEmails,
      'collaboratorIds': <String>[], // populated later
      'isDeleted': false,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    return doc.id;
  }

  Future<void> updateTrip({
    required String tripId,
    required String name,
    required String destinationCity,
    required String destinationCountry,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> collaboratorEmails,
  }) async {
    await _trips.doc(tripId).update({
      'name': name,
      'destinationCity': destinationCity,
      'destinationCountry': destinationCountry,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'collaboratorEmails': collaboratorEmails,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> softDeleteTrip(String tripId) async {
    await _trips.doc(tripId).update({
      'isDeleted': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<Trip> streamTrip(String tripId) {
    return _trips.doc(tripId).snapshots().map(Trip.fromDoc);
  }

  // ============================================================
  // ITINERARY ACTIVITIES
  // ============================================================

  CollectionReference<Map<String, dynamic>> _activitiesRef(String tripId) =>
      _trips.doc(tripId).collection('itineraryActivities');

  Stream<List<ActivityItem>> streamActivitiesForDay(
    String tripId,
    int dayIndex,
  ) {
    return _activitiesRef(tripId)
        .where('dayIndex', isEqualTo: dayIndex)
        .orderBy('orderIndex')
        .snapshots()
        .map((snap) => snap.docs.map(ActivityItem.fromDoc).toList());
  }

  Future<void> addActivity({
    required String tripId,
    required String title,
    required int dayIndex,
    String? note,
    String? timeOfDay,
    String? apiPlaceId,
    double? lat,
    double? lon,
  }) async {
    final existing = await _activitiesRef(tripId)
        .where('dayIndex', isEqualTo: dayIndex)
        .get();

    final nextOrderIndex = existing.docs.length;
    final now = DateTime.now();

    await _activitiesRef(tripId).add({
      'title': title,
      'note': note,
      'timeOfDay': timeOfDay,
      'dayIndex': dayIndex,
      'orderIndex': nextOrderIndex,
      'createdBy': _uid,
      'apiPlaceId': apiPlaceId,
      'lat': lat,
      'lon': lon,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    await _trips.doc(tripId).update({
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> reorderActivities({
    required String tripId,
    required List<ActivityItem> reordered,
  }) async {
    final batch = _db.batch();
    final now = DateTime.now();

    for (int i = 0; i < reordered.length; i++) {
      batch.update(
        _activitiesRef(tripId).doc(reordered[i].id),
        {
          'orderIndex': i,
          'updatedAt': Timestamp.fromDate(now),
        },
      );
    }

    batch.update(_trips.doc(tripId), {
      'updatedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  Future<void> deleteActivity(String tripId, String activityId) async {
    await _activitiesRef(tripId).doc(activityId).delete();
    await _trips.doc(tripId).update({
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ============================================================
  // PACKING LIST (SECTION 8)
  // ============================================================

  CollectionReference<Map<String, dynamic>> _packingRef(String tripId) =>
      _trips.doc(tripId).collection('packingItems');

  Stream<List<PackingItem>> streamPacking(String tripId) {
    return _packingRef(tripId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PackingItem.fromDoc).toList());
  }

  Future<void> addPackingItem(String tripId, String label) async {
    final now = DateTime.now();

    await _packingRef(tripId).add({
      'label': label,
      'isChecked': false,
      'addedBy': _uid,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    await _trips.doc(tripId).update({
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> togglePackingItem(String tripId, PackingItem item) async {
    await _packingRef(tripId).doc(item.id).update({
      'isChecked': !item.isChecked,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deletePackingItem(String tripId, String itemId) async {
    await _packingRef(tripId).doc(itemId).delete();
  }

  // ============================================================
  // CHECKLIST (SECTION 9 READY)
  // ============================================================

  CollectionReference<Map<String, dynamic>> _checklistRef(String tripId) =>
      _trips.doc(tripId).collection('checklistItems');

  Stream<List<ChecklistItem>> streamChecklist(String tripId) {
    return _checklistRef(tripId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChecklistItem.fromDoc).toList());
  }

  Future<void> addChecklistItem(String tripId, String label) async {
    final now = DateTime.now();

    await _checklistRef(tripId).add({
      'label': label,
      'isCompleted': false,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    await _trips.doc(tripId).update({
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> toggleChecklistItem(
    String tripId,
    ChecklistItem item,
  ) async {
    await _checklistRef(tripId).doc(item.id).update({
      'isCompleted': !item.isCompleted,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteChecklistItem(String tripId, String itemId) async {
    await _checklistRef(tripId).doc(itemId).delete();
  }
}
