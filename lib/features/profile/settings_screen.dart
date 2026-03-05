import 'package:flutter/material.dart';
import 'change_password_screen.dart';
import 'payment_method_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _notifications = true;
  String _selectedLanguage = "English";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FA),

      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ================= ACCOUNT (TOP) =================
            _sectionTitle('Account'),

            _settingsTile(
              icon: Icons.person,
              title: 'Account Information',
              onTap: () {},
            ),

            _settingsTile(
              icon: Icons.payment,
              title: 'Payment Methods',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentMethodPage(),
                  ),
                );
              },
            ),

            _settingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: _selectedLanguage,
              onTap: _showLanguageDialog,
            ),

            const SizedBox(height: 25),

            // ================= PREFERENCES =================
            _sectionTitle('Preferences'),

            _settingsTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              trailing: Switch(
                value: _darkMode,
                activeColor: Colors.deepPurple,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                  });
                },
              ),
            ),

            _settingsTile(
              icon: Icons.notifications_active,
              title: 'Notifications',
              trailing: Switch(
                value: _notifications,
                activeColor: Colors.deepPurple,
                onChanged: (value) {
                  setState(() {
                    _notifications = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 25),

            // ================= SECURITY =================
            _sectionTitle('Security'),

            _settingsTile(
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordPage(),
                  ),
                );
              },
            ),

            _settingsTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {},
            ),

            const SizedBox(height: 25),

            // ================= ABOUT =================
            _sectionTitle('About'),

            _settingsTile(
              icon: Icons.info,
              title: 'About Uthenga',
              subtitle: 'Version 1.0.0',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ================= SETTINGS TILE =================
  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // ================= LANGUAGE DIALOG =================
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Select Language"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageOption("English"),
              _languageOption("French"),
              _languageOption("Spanish"),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(String language) {
    return RadioListTile(
      value: language,
      groupValue: _selectedLanguage,
      activeColor: Colors.deepPurple,
      title: Text(language),
      onChanged: (value) {
        setState(() {
          _selectedLanguage = value!;
        });
        Navigator.pop(context);
      },
    );
  }
}