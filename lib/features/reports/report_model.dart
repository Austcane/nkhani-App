import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String newsId;
  final String reporterId;
  final String reason;
  final DateTime createdAt;
  final String status;

  Report({
    required this.id,
    required this.newsId,
    required this.reporterId,
    required this.reason,
    required this.createdAt,
    required this.status,
  });

  factory Report.fromMap(Map<String, dynamic> data, String id) {
    final rawCreatedAt = data['createdAt'];
    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);

    return Report(
      id: id,
      newsId: data['newsId'] ?? '',
      reporterId: data['reporterId'] ?? '',
      reason: data['reason'] ?? '',
      createdAt: createdAt,
      status: data['status'] ?? 'open',
    );
  }
}
