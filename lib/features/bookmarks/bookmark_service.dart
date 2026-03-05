import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nkhani/features/feed/news_model.dart';

class BookmarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _bookmarkRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('bookmarks');
  }

  Stream<bool> watchBookmarkStatus(String uid, String newsId) {
    return _bookmarkRef(uid).doc(newsId).snapshots().map((doc) => doc.exists);
  }

  Future<void> addBookmark({
    required String uid,
    required News news,
  }) async {
    await _bookmarkRef(uid).doc(news.id).set({
      'newsId': news.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeBookmark({
    required String uid,
    required String newsId,
  }) async {
    await _bookmarkRef(uid).doc(newsId).delete();
  }

  Stream<List<News>> watchBookmarks(String uid) {
    return _bookmarkRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final futures = snapshot.docs.map((doc) async {
        final data = doc.data();
        final newsId = data['newsId'];
        if (newsId is! String || newsId.isEmpty) return null;
        final newsDoc = await _firestore.collection('news').doc(newsId).get();
        if (!newsDoc.exists || newsDoc.data() == null) return null;
        return News.fromMap(newsDoc.data()!, newsDoc.id);
      }).toList();

      final results = await Future.wait(futures);
      return results.whereType<News>().toList();
    });
  }
}
