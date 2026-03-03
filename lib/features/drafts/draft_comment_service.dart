import 'package:cloud_firestore/cloud_firestore.dart';
import 'draft_comment_model.dart';

class DraftCommentService {
  final CollectionReference _commentsRef =
      FirebaseFirestore.instance.collection('draft_comments');

  Stream<List<DraftComment>> watchComments(String newsId) {
    return _commentsRef
        .where('newsId', isEqualTo: newsId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) =>
              DraftComment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> addComment({
    required String newsId,
    required String newsAuthorId,
    required String? organizationId,
    required String authorId,
    required String message,
  }) async {
    await _commentsRef.add({
      'newsId': newsId,
      'newsAuthorId': newsAuthorId,
      'organizationId': organizationId,
      'authorId': authorId,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
