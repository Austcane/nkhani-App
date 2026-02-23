import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "Admin Access Granted 🛠",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text("You can manage news here."),
          ],
        ),
      ),
    );
  }
}
