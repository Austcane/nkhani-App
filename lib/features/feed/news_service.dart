import 'package:cloud_firestore/cloud_firestore.dart';
import 'news_model.dart';

class NewsService {
  final CollectionReference _newsRef =
  FirebaseFirestore.instance.collection('news');

  Stream<List<News>> getNewsFeed() {
    return _newsRef
        .where('published', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          News.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }
}