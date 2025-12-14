import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trip.dart';
import '../models/activity_item.dart';
import '../models/packing_item.dart';
import '../models/checklist_item.dart';

class TripsService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _trips =>
      _db.collection('trips');

  // -------------------------
  // Trips
  // -------------------------

  Stream<List<Trip>> streamMyTrips() {
    // Firestore doesn't support "ownerId == uid OR collaboratorIds contains uid" in one query.
    // Simple approach: maintain collaboratorIds and do two queries, then merge.
    // For student projects: easiest is to use two streams and merge in UI.
    // Here: we provide two streams separately.
    throw UnimplementedError('Use streamOwnedTrips + streamSharedTrips in UI.');
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
      'collaboratorIds': <String>[], // can be populated later
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
    return _trips.doc(tripId).snapshots().map((doc) => Trip.fromDoc(doc));
  }

  // -------------------------
  // Itinerary activities
  // -------------------------

  CollectionReference<Map<String, dynamic>> _activitiesRef(String tripId) =>
      _trips.doc(tripId).collection('itineraryActivities');

  Stream<List<ActivityItem>> streamActivitiesForDay(String tripId, int dayIndex) {
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
    // Find next orderIndex for the day (simple approach: count existing)
    final existing = await _activitiesRef(tripId)
        .where('dayIndex', isEqualTo: dayIndex)
        .get();

    final nextOrder = existing.docs.length;

    final now = DateTime.now();
    await _activitiesRef(tripId).add({
      'title': title,
      'note': note,
      'timeOfDay': timeOfDay,
      'dayIndex': dayIndex,
      'orderIndex': nextOrder,
      'createdBy': _uid,
      'apiPlaceId': apiPlaceId,
      'lat': lat,
      'lon': lon,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    // Bump trip updatedAt so trips list sorts by recent changes
    await _trips.doc(tripId).update({'updatedAt': Timestamp.fromDate(now)});
  }

  Future<void> reorderActivities({
    required String tripId,
    required List<ActivityItem> reordered,
  }) async {
    // Batch update orderIndex for all affected docs.
    final batch = _db.batch();
    final now = DateTime.now();

    for (int i = 0; i < reordered.length; i++) {
      final docRef = _activitiesRef(tripId).doc(reordered[i].id);
      batch.update(docRef, {
        'orderIndex': i,
        'updatedAt': Timestamp.fromDate(now),
      });
    }

    batch.update(_trips.doc(tripId), {'updatedAt': Timestamp.fromDate(now)});
    await batch.commit();
  }

  Future<void> deleteActivity(String tripId, String activityId) async {
    await _activitiesRef(tripId).doc(activityId).delete();
    await _trips.doc(tripId).update({'updatedAt': Timestamp.fromDate(DateTime.now())});
  }

  // -------------------------
  // Packing list (real-time)
  // -------------------------

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
    await _trips.doc(tripId).update({'updatedAt': Timestamp.fromDate(now)});
  }

  Future<void> togglePackingItem(String tripId, PackingItem item) async {
    final now = DateTime.now();
    await _packingRef(tripId).doc(item.id).update({
      'isChecked': !item.isChecked,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> deletePackingItem(String tripId, String itemId) async {
    await _packingRef(tripId).doc(itemId).delete();
  }

  // -------------------------
  // Checklist (real-time)
  // -------------------------

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
    await _trips.doc(tripId).update({'updatedAt': Timestamp.fromDate(now)});
  }

  Future<void> toggleChecklistItem(String tripId, ChecklistItem item) async {
    final now = DateTime.now();
    await _checklistRef(tripId).doc(item.id).update({
      'isCompleted': !item.isCompleted,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> deleteChecklistItem(String tripId, String itemId) async {
    await _checklistRef(tripId).doc(itemId).delete();
  }
}
