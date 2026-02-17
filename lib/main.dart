import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nkhani/features/auth/login_screen.dart';
import 'package:nkhani/features/home/home_screen.dart';
import 'package:nkhani/navigation/main_navigation.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/home/user_home_screen.dart';
import 'package:nkhani/features/home/admin_home_screen.dart';


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
      home: const AuthWrapper(), // ✅ THIS IS KEY
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Logged in
        if (snapshot.hasData) {
          return const MainNavigation();
        }

        // Logged out
        return const LoginScreen();
      },
    );
  }
}

