import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String action;
  final String actorId;
  final String targetType;
  final String targetId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.action,
    required this.actorId,
    required this.targetType,
    required this.targetId,
    required this.metadata,
    required this.createdAt,
  });

  factory AuditLog.fromMap(Map<String, dynamic> data, String id) {
    final rawCreatedAt = data['createdAt'];
    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);

    return AuditLog(
      id: id,
      action: data['action'] ?? '',
      actorId: data['actorId'] ?? '',
      targetType: data['targetType'] ?? '',
      targetId: data['targetId'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: createdAt,
    );
  }
}
