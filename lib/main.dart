import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/login_screen.dart';
import 'package:nkhani/features/auth/splash_screen.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/navigation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const NkhaniApp());
}

class NkhaniApp extends StatelessWidget {
  const NkhaniApp({super.key});

  static const Color _primary = Color(0xFF8B1D76);
  static const Color _secondary = Color(0xFFF4E848);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nkhani',
      theme: ThemeData(
        primaryColor: _primary,
        colorScheme: const ColorScheme.light(
          primary: _primary,
          secondary: _secondary,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

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

            return const MainNavigation();
          },
        );
      },
    );
  }
}
