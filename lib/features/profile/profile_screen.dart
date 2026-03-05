import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/organizations/org_request_screen.dart';
import 'package:nkhani/features/organizations/org_story_submit_screen.dart';
import 'package:nkhani/features/profile/edit_profile_screen.dart';
import 'package:nkhani/features/profile/settings_screen.dart';
import 'package:nkhani/features/subscription/subscription_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isActivating = false;

  final LinearGradient _purpleGradient = const LinearGradient(
    colors: [
      Color(0xFF7B1FA2),
      Color(0xFF9C27B0),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
      body: StreamBuilder<AppUser?>(
        stream: UserService().watchUser(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final appUser = snapshot.data!;

          return Column(
            children: [
              // 🔥 Gradient Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                    top: 60, left: 20, right: 20, bottom: 30),
                decoration: BoxDecoration(
                  gradient: _purpleGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      backgroundImage: appUser.photoUrl?.isNotEmpty == true
                          ? NetworkImage(appUser.photoUrl!)
                          : null,
                      child: appUser.photoUrl?.isNotEmpty == true
                          ? null
                          : Text(
                        appUser.name.isNotEmpty
                            ? appUser.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      appUser.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appUser.email,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // 🔥 Content Section
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildCardTile(
                      icon: Icons.edit,
                      title: 'Edit Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditProfileScreen(user: appUser),
                          ),
                        );
                      },
                    ),

                    _buildCardTile(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                    ),

                    _buildCardTile(
                      icon: Icons.subscriptions,
                      title: 'Subscription',
                      subtitle: _statusText(appUser),
                      trailing: appUser.subscriptionActive
                          ? const Icon(Icons.check_circle,
                          color: Colors.green)
                          : TextButton(
                        onPressed: _isActivating
                            ? null
                            : () => _activateSubscription(user.uid),
                        child: const Text(
                          'Activate',
                          style: TextStyle(
                            color: Color(0xFF9C27B0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    _buildCardTile(
                      icon: Icons.business,
                      title: 'Request Organization',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const OrganizationRequestScreen(),
                          ),
                        );
                      },
                    ),

                    if (appUser.isOrganizationAdmin)
                      _buildCardTile(
                        icon: Icons.post_add,
                        title: 'Organization Studio',
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

                    _buildCardTile(
                      icon: Icons.logout,
                      title: 'Log out',
                      iconColor: Colors.redAccent,
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color iconColor = Colors.deepPurple,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}