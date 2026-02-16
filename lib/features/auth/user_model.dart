import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool subscriptionActive;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.subscriptionActive,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      subscriptionActive: data['subscriptionActive'] ?? false,
    );
  }
}
