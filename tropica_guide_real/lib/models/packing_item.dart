import 'package:cloud_firestore/cloud_firestore.dart';

class PackingItem {
  final String id;
  final String label;
  final bool isChecked;
  final String addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PackingItem({
    required this.id,
    required this.label,
    required this.isChecked,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'isChecked': isChecked,
      'addedBy': addedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static PackingItem fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PackingItem(
      id: doc.id,
      label: (data['label'] ?? '') as String,
      isChecked: (data['isChecked'] ?? false) as bool,
      addedBy: (data['addedBy'] ?? '') as String,
      createdAt: ((data['createdAt'] as Timestamp?)?.toDate()) ?? DateTime.now(),
      updatedAt: ((data['updatedAt'] as Timestamp?)?.toDate()) ?? DateTime.now(),
    );
  }
}

