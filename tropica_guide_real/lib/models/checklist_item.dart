import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistItem {
  final String id;
  final String label;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChecklistItem({
    required this.id,
    required this.label,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static ChecklistItem fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChecklistItem(
      id: doc.id,
      label: (data['label'] ?? '') as String,
      isCompleted: (data['isCompleted'] ?? false) as bool,
      createdAt: ((data['createdAt'] as Timestamp?)?.toDate()) ?? DateTime.now(),
      updatedAt: ((data['updatedAt'] as Timestamp?)?.toDate()) ?? DateTime.now(),
    );
  }
}

