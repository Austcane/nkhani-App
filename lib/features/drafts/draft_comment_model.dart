import 'package:cloud_firestore/cloud_firestore.dart';

class DraftComment {
  final String id;
  final String newsId;
  final String newsAuthorId;
  final String? organizationId;
  final String authorId;
  final String message;
  final DateTime createdAt;

  DraftComment({
    required this.id,
    required this.newsId,
    required this.newsAuthorId,
    required this.organizationId,
    required this.authorId,
    required this.message,
    required this.createdAt,
  });

  factory DraftComment.fromMap(Map<String, dynamic> data, String id) {
    final rawCreatedAt = data['createdAt'];
    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);

    return DraftComment(
      id: id,
      newsId: data['newsId'] ?? '',
      newsAuthorId: data['newsAuthorId'] ?? '',
      organizationId: data['organizationId'],
      authorId: data['authorId'] ?? '',
      message: data['message'] ?? '',
      createdAt: createdAt,
    );
  }
}
