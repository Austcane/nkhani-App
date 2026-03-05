import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/bookmarks/saved_stories_screen.dart';
import 'package:nkhani/features/home/admin_home_screen.dart';
import 'package:nkhani/features/organizations/org_request_screen.dart';
import 'package:nkhani/features/organizations/org_story_submit_screen.dart';
import 'package:nkhani/features/profile/edit_profile_screen.dart';
import 'package:nkhani/features/subscription/subscription_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isActivating = false;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _activateSubscription(String uid) async {
    setState(() => _isActivating = true);

    try {
      await _subscriptionService.activatePaidSubscription(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription activated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isActivating = false);
      }
    }
  }

  String _statusText(AppUser appUser) {
    if (appUser.subscriptionActive) {
      return 'Paid subscription is active.';
    }

    if (appUser.isTrialActive) {
      return 'Trial active: ${appUser.trialDaysLeft} day(s) remaining.';
    }

    return 'No active access. Subscribe for MWK 500.';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: StreamBuilder<AppUser?>(
        stream: UserService().watchUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('User profile not found.'));
          }

          final appUser = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: appUser.photoUrl?.isNotEmpty == true
                            ? NetworkImage(appUser.photoUrl!)
                            : null,
                        child: appUser.photoUrl?.isNotEmpty == true
                            ? null
                            : Text(
                                appUser.name.isNotEmpty
                                    ? appUser.name
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(
                                  user: appUser,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appUser.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appUser.email,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusText(appUser),
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.subscriptions),
                title: const Text('Subscription'),
                subtitle: Text(_statusText(appUser)),
                trailing: appUser.subscriptionActive
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : TextButton(
                        onPressed: _isActivating
                            ? null
                            : () => _activateSubscription(user.uid),
                        child: _isActivating
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Activate'),
                      ),
              ),
              const Divider(),
              if (appUser.isSuperuser)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Admin Dashboard'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminHomeScreen(),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Request Organization'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrganizationRequestScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark),
                title: const Text('Saved Stories'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedStoriesScreen(),
                    ),
                  );
                },
              ),
              if (appUser.isSuperuser || appUser.isOrganizationAdmin)
                ListTile(
                  leading: const Icon(Icons.post_add),
                  title: const Text('Organization Studio'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const OrganizationStorySubmitScreen(),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Log out'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _logout,
              ),
            ],
          );
        },
      ),
    );
  }
}
