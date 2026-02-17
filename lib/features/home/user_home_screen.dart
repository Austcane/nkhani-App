import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // AuthWrapper will automatically redirect to LoginScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nkhani"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "User Home 📰",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
