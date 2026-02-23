import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class UserService {
  final _users = FirebaseFirestore.instance.collection('users');

  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, uid);
  }
}
