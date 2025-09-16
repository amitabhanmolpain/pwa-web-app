import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'setup_profile_personal_screen.dart';
import 'language_selection_screen.dart';
import 'support_center_screen.dart';
import 'help_faq_screen.dart';
import 'privacy_policy_screen.dart';
import 'security_tips_screen.dart';
import 'theme_notifier.dart';
import 'login_screen.dart'; // make sure this import points to your LoginScreen

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  final storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: true);
    final bool isDarkMode = themeNotifier.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile & Account Section
            _buildSectionHeader('Profile & Account'),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.person_outline,
                    title: 'Setup Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const SetupProfilePersonalScreen()),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.language,
                    title: 'Language',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const LanguageSelectionScreen()),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.security,
                    title: 'Privacy & Security',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen()),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.dark_mode,
                    title: 'Night Mode',
                    subtitle: 'Dark theme for night shifts',
                    trailing: Switch.adaptive(
                      value: isDarkMode,
                      onChanged: (value) {
                        themeNotifier.setTheme(value);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Support Section
            _buildSectionHeader('Support'),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.help_outline,
                    title: 'Help & FAQ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HelpFaqScreen()),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.support_agent,
                    title: 'Contact Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SupportCenterScreen()),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.lock_outline,
                    title: 'Security Tips',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SecurityTipsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Actions Section
            _buildSectionHeader('Account'),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    titleColor: Colors.red,
                    onTap: () {
                      _showSignOutConfirmation(context);
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    titleColor: Colors.red,
                    onTap: () {
                      _showDeleteAccountConfirmation(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // App Version
            Center(
              child: Column(
                children: [
                  Text(
                    'App Version 1.0.0',
                    style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2023 Your App Name',
                    style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 16.0),
      child: Divider(height: 1, thickness: 0.5),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      minLeadingWidth: 24,
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // close dialog
                await storage.deleteAll(); // clear local storage/session

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
              'This action cannot be undone. All your data will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // close dialog

                // Debug: print all keys in storage to find the correct token key
                Map<String, String> allValues = await storage.readAll();
                print('Stored keys: ' + allValues.toString());
                String? token = allValues['auth_token'] ??
                    allValues['token'] ??
                    allValues['access_token'];
                if (token == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'User not logged in (no token found in storage)')),
                  );
                  return;
                }

                try {
                  var url = Uri.parse('http://localhost:8080/api/user/delete');
                  var response = await http.delete(
                    url,
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                  );

                  if (response.statusCode == 200) {
                    await storage.deleteAll(); // clear local session

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Account deleted successfully')),
                    );
                  } else {
                    var body = json.decode(response.body);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: ${body['message']}')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
