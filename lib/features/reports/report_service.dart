import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_model.dart';

class ReportService {
  final CollectionReference _reportsRef =
      FirebaseFirestore.instance.collection('reports');

  Stream<List<Report>> watchOpenReports() {
    return _reportsRef
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => Report.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> createReport({
    required String newsId,
    required String reporterId,
    required String reason,
  }) async {
    await _reportsRef.add({
      'newsId': newsId,
      'reporterId': reporterId,
      'reason': reason,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> resolveReport(String reportId) async {
    await _reportsRef.doc(reportId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
