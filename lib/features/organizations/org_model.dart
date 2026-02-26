import 'package:cloud_firestore/cloud_firestore.dart';

class Organization {
  final String id;
  final String name;
  final String contactEmail;
  final String description;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  Organization({
    required this.id,
    required this.name,
    required this.contactEmail,
    required this.description,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory Organization.fromMap(Map<String, dynamic> data, String id) {
    final rawCreatedAt = data['createdAt'];
    final rawReviewedAt = data['reviewedAt'];

    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
    final reviewedAt = rawReviewedAt is Timestamp
        ? rawReviewedAt.toDate()
        : null;

    return Organization(
      id: id,
      name: data['name'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      createdBy: data['createdBy'] ?? '',
      createdAt: createdAt,
      reviewedBy: data['reviewedBy'],
      reviewedAt: reviewedAt,
    );
  }
}
