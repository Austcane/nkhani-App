import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/user_service.dart';

class AdminBootstrapScreen extends StatefulWidget {
  const AdminBootstrapScreen({super.key});

  @override
  State<AdminBootstrapScreen> createState() => _AdminBootstrapScreenState();
}

class _AdminBootstrapScreenState extends State<AdminBootstrapScreen> {
  final _userService = UserService();
  bool _isUpdating = false;
  late final Future<bool> _bootstrapDoneFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapDoneFuture = _userService.isBootstrapDone();
  }

  Future<void> _makeAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUpdating = true);

    try {
      await _userService.bootstrapSuperuser(user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are now a superuser.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin bootstrap failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Bootstrap'),
      ),
      body: FutureBuilder<bool>(
        future: _bootstrapDoneFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final done = snapshot.data == true;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
              'Make this account a superuser',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  done
                      ? 'Bootstrap already completed. Use the admin dashboard to manage roles.'
                      : 'Use this once to promote your first superuser account.',
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: done || _isUpdating ? null : _makeAdmin,
                  icon: _isUpdating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.admin_panel_settings),
                  label: const Text('Make Me Superuser'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
