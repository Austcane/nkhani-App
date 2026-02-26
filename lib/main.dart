import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/login_screen.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/home/admin_home_screen.dart';
import 'package:nkhani/navigation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const NkhaniApp());
}

class NkhaniApp extends StatelessWidget {
  const NkhaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nkhani',
      theme: ThemeData(
        primaryColor: const Color(0xFF8A1E78),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF8A1E78),
          secondary: Color(0xFFF8F148),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final firebaseUser = authSnapshot.data!;

        return FutureBuilder(
          future: UserService().ensureUserProfile(firebaseUser),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnapshot.hasError) {
              final error = userSnapshot.error;
              var message = 'Failed to load user profile.';
              if (error is FirebaseException &&
                  error.code == 'permission-denied') {
                message = 'Firestore permission denied. Update your Firestore '
                    'rules and retry.';
              }
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Profile Issue'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ],
                ),
                body: Center(child: Text(message)),
              );
            }

            if (!userSnapshot.hasData || userSnapshot.data == null) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Profile Issue'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ],
                ),
                body: const Center(
                  child: Text('User profile not found. Please retry.'),
                ),
              );
            }

            final appUser = userSnapshot.data!;

            if (appUser.role == 'admin') {
              return const AdminHomeScreen();
            }

            return const MainNavigation();
          },
        );
      },
    );
  }
}
