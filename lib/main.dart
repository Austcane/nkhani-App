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
      builder: (context, authSnapshot) {
        // 1️⃣ Still checking auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2️⃣ Not logged in → Login
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final firebaseUser = authSnapshot.data!;

        // 3️⃣ Logged in → fetch Firestore user
        return FutureBuilder(
          future: UserService().getUser(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || userSnapshot.data == null) {
              return const Scaffold(
                body: Center(child: Text("User profile not found")),
              );
            }

            final appUser = userSnapshot.data!;

            // 4️⃣ Route by role
            if (appUser.role == 'admin') {
              return const AdminHomeScreen();
            }

            return const MainNavigation(); // normal user
          },
        );
      },
    );
  }
}


