import 'package:cloud_firestore/cloud_firestore.dart';
import 'news_model.dart';

class NewsService {
  final CollectionReference _newsRef =
  FirebaseFirestore.instance.collection('news');

  Stream<List<NewsArticle>> getNewsFeed() {
    return _newsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NewsArticle.fromFirestore(doc))
          .toList();
    });
  }
}
