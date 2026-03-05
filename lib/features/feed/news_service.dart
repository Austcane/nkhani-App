import 'package:cloud_firestore/cloud_firestore.dart';
import 'news_model.dart';

class NewsService {
  final CollectionReference _newsRef =
      FirebaseFirestore.instance.collection('news');

  Stream<List<News>> getNewsFeed() {
    return _newsRef
        .where('published', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => News.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<News>> getNewsFeedByCategory(String category) {
    return _newsRef
        .where('published', isEqualTo: true)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => News.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<News>> searchPublishedNewsByTitle(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return Stream.value([]);
    }

    return _newsRef
        .where('published', isEqualTo: true)
        .orderBy('titleLower')
        .startAt([normalized])
        .endAt(['$normalized\uf8ff'])
        .limit(30)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) =>
                  News.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Stream<List<News>> getAdminNewsFeed(String authorId) {
    return _newsRef
        .where('authorId', isEqualTo: authorId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => News.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<News>> getDrafts() {
    return _newsRef
        .where('published', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => News.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<News>> getDraftsByAuthor(String authorId) {
    return _newsRef
        .where('authorId', isEqualTo: authorId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => News.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((news) => news.published == false)
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<News>> getPublishedNewsByOrganization(String organizationId) {
    return _newsRef
        .where('published', isEqualTo: true)
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => News.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<News?> getNewsById(String newsId) async {
    final doc = await _newsRef.doc(newsId).get();
    if (!doc.exists || doc.data() == null) return null;
    return News.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> createNews({
    required String title,
    String? summary,
    required String content,
    List<String> imageUrls = const [],
    required String authorId,
    String? organizationId,
    String category = 'News',
  }) async {
    await _newsRef.add({
      'title': title,
      'titleLower': title.trim().toLowerCase(),
      'summary': summary,
      'content': content,
      'imageUrls': imageUrls,
      'authorId': authorId,
      'organizationId': organizationId,
      'category': category,
      'published': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setPublished({
    required String newsId,
    required bool published,
    String? title,
    String? category,
  }) async {
    final data = <String, dynamic>{
      'published': published,
    };
    if (title != null) {
      data['titleLower'] = title.trim().toLowerCase();
    }
    if (category != null) {
      data['category'] = category;
    }
    await _newsRef.doc(newsId).update(data);
  }

  Future<void> setTitleLower(String newsId, String title) async {
    await _newsRef.doc(newsId).update({
      'titleLower': title.trim().toLowerCase(),
    });
  }

  Future<void> deleteNews(String newsId) async {
    await _newsRef.doc(newsId).delete();
  }
}
