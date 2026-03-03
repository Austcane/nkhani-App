import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_model.dart';

class NotificationService {
  final CollectionReference _notificationsRef =
      FirebaseFirestore.instance.collection('notifications');

  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => AppNotification.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<int> watchUnreadCount(String userId) {
    return watchUserNotifications(userId).map((items) {
      return items.where((item) => !item.read).length;
    });
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    await _notificationsRef.add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'read': false,
      'metadata': metadata ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({'read': true});
  }
}
