import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/bookmarks/saved_stories_screen.dart';
import 'package:nkhani/features/home/admin_home_screen.dart';
import 'package:nkhani/features/organizations/org_request_screen.dart';
import 'package:nkhani/features/organizations/org_story_submit_screen.dart';
import 'package:nkhani/features/profile/edit_profile_screen.dart';
import 'package:nkhani/features/profile/settings_screen.dart';
import 'package:nkhani/features/subscription/subscription_service.dart';

const Color _brand = Color(0xFF8B1D76);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
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

          final bottomPadding = MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight +
              16;

          return ListView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
            children: [
              _ProfileHeader(
                name: appUser.name,
                email: appUser.email,
                photoUrl: appUser.photoUrl,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(user: appUser),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _sectionLabel('Account'),
              _sectionCard([
                _ProfileAction(
                  icon: Icons.bookmark,
                  title: 'Saved Stories',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavedStoriesScreen(),
                      ),
                    );
                  },
                ),
                _ProfileAction(
                  icon: Icons.subscriptions,
                  title: 'Subscription',
                  subtitle: _statusText(appUser),
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Activate'),
                        ),
                ),
                if (appUser.isSuperuser)
                  _ProfileAction(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Dashboard',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminHomeScreen(),
                        ),
                      );
                    },
                  ),
              ]),
              const SizedBox(height: 16),
              _sectionLabel('Organizations'),
              _sectionCard([
                _ProfileAction(
                  icon: Icons.business,
                  title: 'Request Organization',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrganizationRequestScreen(),
                      ),
                    );
                  },
                ),
                if (appUser.isSuperuser || appUser.isOrganizationAdmin)
                  _ProfileAction(
                    icon: Icons.post_add,
                    title: 'Organization Studio',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrganizationStorySubmitScreen(),
                        ),
                      );
                    },
                  ),
              ]),
              const SizedBox(height: 16),
              _sectionLabel('Account Actions'),
              _sectionCard([
                _ProfileAction(
                  icon: Icons.logout,
                  iconColor: Colors.redAccent,
                  title: 'Log out',
                  onTap: _logout,
                ),
              ]),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final handle = email.contains('@')
        ? '@${email.split('@').first}'
        : '@user';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: photoUrl?.isNotEmpty == true
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl?.isNotEmpty == true
                    ? null
                    : Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _brand,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            handle,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 160,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: onEdit,
              child: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    ),
  );
}

class _ProfileAction {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileAction({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor = _brand,
    this.trailing,
    this.onTap,
  });
}

Widget _sectionCard(List<_ProfileAction> actions) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          ListTile(
            leading: Icon(actions[i].icon, color: actions[i].iconColor),
            title: Text(
              actions[i].title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: actions[i].subtitle != null
                ? Text(actions[i].subtitle!)
                : null,
            trailing:
                actions[i].trailing ?? const Icon(Icons.chevron_right),
            onTap: actions[i].onTap,
          ),
          if (i != actions.length - 1)
            const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ],
    ),
  );
}
