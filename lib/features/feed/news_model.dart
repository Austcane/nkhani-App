import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String title;
  final String? summary;
  final String content;
  final List<String> imageUrls;
  final String authorId;
  final String? organizationId;
  final String category;
  final DateTime createdAt;
  final bool published;

  News({
    required this.id,
    required this.title,
    this.summary,
    required this.content,
    required this.imageUrls,
    required this.authorId,
    this.organizationId,
    required this.category,
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
      summary: data['summary'],
      content: data['content'] ?? '',
      imageUrls: (data['imageUrls'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      authorId: data['authorId'] ?? '',
      organizationId: data['organizationId'],
      category: data['category'] ?? 'News',
      createdAt: createdAt,
      published: data['published'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      'imageUrls': imageUrls,
      'authorId': authorId,
      'organizationId': organizationId,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'published': published,
    };
  }

  bool get isValidDraft {
    if (title.trim().isEmpty) return false;
    if (content.trim().isEmpty) return false;
    if (authorId.trim().isEmpty) return false;
    if (category.trim().isEmpty) return false;
    return true;
  }

  static const List<String> categories = [
    'News',
    'Politics',
    'Sports',
    'Entertainment',
    'Business',
    'Technology',
    'World',
  ];
}
