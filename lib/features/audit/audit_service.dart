import 'package:cloud_firestore/cloud_firestore.dart';
import 'audit_model.dart';

class AuditService {
  final CollectionReference _auditRef =
      FirebaseFirestore.instance.collection('audit_logs');

  Future<void> logAction({
    required String action,
    required String actorId,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? metadata,
  }) async {
    await _auditRef.add({
      'action': action,
      'actorId': actorId,
      'targetType': targetType,
      'targetId': targetId,
      'metadata': metadata ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AuditLog>> watchLogs() {
    return _auditRef.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) =>
              AuditLog.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }
}
