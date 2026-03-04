import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';

class UserService {
  final _users = FirebaseFirestore.instance.collection('users');
  final _config = FirebaseFirestore.instance.collection('config');

  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, uid);
  }

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.data()!, uid);
    });
  }

  Stream<List<AppUser>> watchAllUsers() {
    return _users.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    await _users.doc(uid).update({'role': role});
  }

  Future<bool> isBootstrapDone() async {
    final doc = await _config.doc('bootstrap').get();
    return doc.exists;
  }

  Future<void> bootstrapSuperuser(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final configRef = _config.doc('bootstrap');
    batch.set(configRef, {
      'superuserUid': uid,
      'bootstrappedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_users.doc(uid), {'role': 'superuser'});
    await batch.commit();
  }

  Future<AppUser> ensureUserProfile(User firebaseUser) async {
    final docRef = _users.doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!, firebaseUser.uid);
    }

    final email = firebaseUser.email ?? '';
    final displayName = firebaseUser.displayName?.trim();
    final fallbackName = email.isNotEmpty ? email.split('@').first : 'User';
    final trialEndsAt = DateTime.now().add(const Duration(days: 7));

    await docRef.set({
      'name': displayName?.isNotEmpty == true ? displayName : fallbackName,
      'email': email,
      'role': 'user',
      'subscriptionActive': false,
      'trialEndsAt': Timestamp.fromDate(trialEndsAt),
      'createdAt': FieldValue.serverTimestamp(),
      'photoUrl': null,
    });

    final created = await docRef.get();
    return AppUser.fromMap(created.data()!, firebaseUser.uid);
  }

  Future<void> activateSubscription(String uid) async {
    await _users.doc(uid).update({
      'subscriptionActive': true,
      'subscriptionActivatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOrganization({
    required String uid,
    required String? organizationId,
  }) async {
    await _users.doc(uid).update({'organizationId': organizationId});
  }

  Future<void> updateOrganizationRole({
    required String uid,
    required String? organizationRole,
  }) async {
    await _users.doc(uid).update({'organizationRole': organizationRole});
  }

  Future<void> updateUserName({
    required String uid,
    required String name,
  }) async {
    await _users.doc(uid).update({'name': name});
  }

  Future<void> updateUserEmail({
    required String uid,
    required String email,
  }) async {
    await _users.doc(uid).update({'email': email});
  }

  Future<void> updateUserPhoto({
    required String uid,
    required String? photoUrl,
  }) async {
    await _users.doc(uid).update({'photoUrl': photoUrl});
  }
}
