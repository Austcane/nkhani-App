import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/auth/user_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // No Navigator code needed.
    // AuthWrapper will automatically redirect to LoginScreen.
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nkhani Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text("No user logged in"))
          : FutureBuilder<AppUser?>(
        future: UserService().getUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                "User data not found",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final appUser = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, ${appUser.name} 👋",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text("Email: ${appUser.email}"),
                Text("Role: ${appUser.role}"),
                Text(
                  "Subscription: ${appUser.subscriptionActive ? "Active" : "Inactive"}",
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
