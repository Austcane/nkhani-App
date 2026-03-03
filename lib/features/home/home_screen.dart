import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/notifications/notification_screen.dart';
import 'package:nkhani/features/notifications/notification_service.dart';
import 'package:nkhani/features/organizations/org_story_submit_screen.dart';

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
          StreamBuilder<int>(
            stream: NotificationService().watchUnreadCount(user?.uid ?? ''),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              return IconButton(
                onPressed: user == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications),
                    if (unread > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Notifications',
              );
            },
          ),
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
                      if (appUser.isOrganizationAdmin) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Organization Tools',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Organization ID: ${appUser.organizationId}'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const OrganizationStorySubmitScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.post_add),
                          label: const Text('Open Org Studio'),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
