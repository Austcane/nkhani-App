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

  Future<void> createNews({
    required String title,
    String? summary,
    required String content,
    List<String> imageUrls = const [],
    required String authorId,
    String? organizationId,
  }) async {
    await _newsRef.add({
      'title': title,
      'summary': summary,
      'content': content,
      'imageUrls': imageUrls,
      'authorId': authorId,
      'organizationId': organizationId,
      'published': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setPublished({
    required String newsId,
    required bool published,
  }) async {
    await _newsRef.doc(newsId).update({'published': published});
  }

  Future<void> deleteNews(String newsId) async {
    await _newsRef.doc(newsId).delete();
  }
}
