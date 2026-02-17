class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool subscriptionActive;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.subscriptionActive,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      subscriptionActive: data['subscriptionActive'] ?? false,
    );
  }
}
