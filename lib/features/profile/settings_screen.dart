import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/widgets/app_colors.dart';
import 'package:nkhani/theme/theme_controller.dart';
import 'change_password_screen.dart';
import 'payment_method_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  String _selectedLanguage = "English";

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeControllerScope.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom +
        kBottomNavigationBarHeight +
        16;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
        child: Column(
          children: [
            _sectionLabel('Account'),
            _sectionCard([
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
            ]),
            const SizedBox(height: 16),
            _sectionLabel('Preferences'),
            _sectionCard([
              _settingsTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                trailing: Switch(
                  value: themeController.isDark,
                  activeColor: AppColors.primary,
                  onChanged: themeController.setDarkMode,
                ),
              ),
              _settingsTile(
                icon: Icons.notifications_active,
                title: 'Notifications',
                trailing: Switch(
                  value: _notifications,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _notifications = value;
                    });
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _sectionLabel('Security'),
            _sectionCard([
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
            ]),
            const SizedBox(height: 16),
            _sectionLabel('About'),
            _sectionCard([
              _settingsTile(
                icon: Icons.info,
                title: 'About Nkhani',
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),
            ]),
          ],
        ),
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
          content: RadioGroup<String>(
            groupValue: _selectedLanguage,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedLanguage = value;
              });
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                RadioListTile(
                  value: "English",
                  title: Text("English"),
                ),
                RadioListTile(
                  value: "French",
                  title: Text("French"),
                ),
                RadioListTile(
                  value: "Spanish",
                  title: Text("Spanish"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _sectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    ),
  );
}

class _SettingsTile {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}

_SettingsTile _settingsTile({
  required IconData icon,
  required String title,
  String? subtitle,
  Widget? trailing,
  VoidCallback? onTap,
}) {
  return _SettingsTile(
    icon: icon,
    title: title,
    subtitle: subtitle,
    trailing: trailing,
    onTap: onTap,
  );
}

Widget _sectionCard(List<_SettingsTile> actions) {
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
            leading: Icon(actions[i].icon, color: AppColors.primary),
            title: Text(
              actions[i].title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: actions[i].subtitle != null
                ? Text(actions[i].subtitle!)
                : null,
            trailing: actions[i].trailing ??
                const Icon(Icons.chevron_right),
            onTap: actions[i].onTap,
          ),
          if (i != actions.length - 1)
            const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ],
    ),
  );
}
