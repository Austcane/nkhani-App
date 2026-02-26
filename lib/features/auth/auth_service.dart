import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        final trialEndsAt = DateTime.now().add(const Duration(days: 7));

        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'role': 'user',
          'subscriptionActive': false,
          'trialEndsAt': Timestamp.fromDate(trialEndsAt),
          'organizationId': null,
          'organizationRole': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return userCredential.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
