import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String ownerId;
  final String name;
  final String destinationCity;
  final String destinationCountry;
  final DateTime startDate;
  final DateTime endDate;

  // Collaboration: keep emails for invites, keep ids for rules
  final List<String> collaboratorEmails;
  final List<String> collaboratorIds;

  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.destinationCity,
    required this.destinationCountry,
    required this.startDate,
    required this.endDate,
    required this.collaboratorEmails,
    required this.collaboratorIds,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  int get dayCount {
    final days = endDate.difference(startDate).inDays + 1;
    return days < 1 ? 1 : days;
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'destinationCity': destinationCity,
      'destinationCountry': destinationCountry,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'collaboratorEmails': collaboratorEmails,
      'collaboratorIds': collaboratorIds,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static Trip fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Trip(
      id: doc.id,
      ownerId: (data['ownerId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      destinationCity: (data['destinationCity'] ?? '') as String,
      destinationCountry: (data['destinationCountry'] ?? '') as String,
      startDate: ((data['startDate'] as Timestamp).toDate()),
      endDate: ((data['endDate'] as Timestamp).toDate()),
      collaboratorEmails: List<String>.from(data['collaboratorEmails'] ?? const []),
      collaboratorIds: List<String>.from(data['collaboratorIds'] ?? const []),
      isDeleted: (data['isDeleted'] ?? false) as bool,
      createdAt: ((data['createdAt'] as Timestamp?)?.toDate()) ?? DateTime.now(),
      updatedAt: ((data['updatedAt'] as Timestamp?)?.toDate()) ?? DateTime.now(),
    );
  }
}

