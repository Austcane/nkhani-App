import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String? organizationId;
  final DateTime createdAt;
  final bool published;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    this.organizationId,
    required this.createdAt,
    required this.published,
  });

  factory News.fromMap(Map<String, dynamic> data, String id) {
    final rawCreatedAt = data['createdAt'];
    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);

    return News(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      organizationId: data['organizationId'],
      createdAt: createdAt,
      published: data['published'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'organizationId': organizationId,
      'createdAt': Timestamp.fromDate(createdAt),
      'published': published,
    };
  }
}
