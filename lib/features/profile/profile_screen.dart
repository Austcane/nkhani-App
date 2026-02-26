import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/admin/admin_bootstrap_screen.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/organizations/org_request_screen.dart';
import 'package:nkhani/features/organizations/org_story_submit_screen.dart';
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
      appBar: AppBar(title: const Text('Profile')),
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

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appUser.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(appUser.email),
                const SizedBox(height: 12),
                Text(_statusText(appUser)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: appUser.subscriptionActive || _isActivating
                      ? null
                      : () => _activateSubscription(user.uid),
                  icon: _isActivating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payment),
                  label: const Text('Activate Subscription (MWK 500)'),
                ),
                const SizedBox(height: 16),
                if (!appUser.isAdmin)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminBootstrapScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Admin Bootstrap'),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrganizationRequestScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.business),
                  label: const Text('Request Organization'),
                ),
                const SizedBox(height: 16),
                if (appUser.isOrganizationAdmin)
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
                    label: const Text('Submit Org Story'),
                  ),
                if (appUser.isOrganizationAdmin) const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
