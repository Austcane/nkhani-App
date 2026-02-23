import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final DateTime createdAt;
  final bool published;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.createdAt,
    required this.published,
  });

  factory News.fromMap(Map<String, dynamic> data, String id) {
    return News(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      published: data['published'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'published': published,
    };
  }
}