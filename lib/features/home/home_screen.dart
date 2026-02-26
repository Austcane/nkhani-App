import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  String _accessSummary(AppUser appUser) {
    if (appUser.subscriptionActive) {
      return 'Paid subscription active';
    }

    if (appUser.isTrialActive) {
      return 'Free trial active (${appUser.trialDaysLeft} day(s) left)';
    }

    return 'No active subscription';
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
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('No user logged in'))
          : StreamBuilder<AppUser?>(
              stream: UserService().watchUser(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text(
                      'User data not found',
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
                        'Welcome, ${appUser.name}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Email: ${appUser.email}'),
                      Text('Role: ${appUser.role}'),
                      Text('Access: ${appUser.hasAccess ? "Enabled" : "Locked"}'),
                      Text('Status: ${_accessSummary(appUser)}'),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
