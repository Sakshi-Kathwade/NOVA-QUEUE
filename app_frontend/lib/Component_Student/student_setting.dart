// ignore_for_file: unused_import, undefined_hidden_name

import 'package:app_frontend/Component_Staff/admin_dashboard.dart';
import 'package:flutter/material.dart';
import '../Component_Staff/queue_status.dart' hide QueueStatusScreen;
import '../main.dart' show isDarkMode;
import 'package:app_frontend/Component_Staff/theme_pref.dart';
import 'student_dashboard.dart';

class AdminSettingScreen extends StatefulWidget {
  const AdminSettingScreen({super.key});

  @override
  State<AdminSettingScreen> createState() => _AdminSettingScreenState();
}

class _AdminSettingScreenState extends State<AdminSettingScreen> {
  bool notificationsEnabled = true;

  void changePasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: "Current Password"),
            ),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: "New Password"),
            ),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: "Confirm New Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void logoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  void clearCache() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Cache cleared successfully")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const QueueStatusScreen(),
              ),
            );
          },
        ),
        title: const Text("Settings"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Account"),
          _infoTile("Admin Email", "admin@college.com"),
          _infoTile("Role", "Administrator"),

          const SizedBox(height: 16),

          _sectionTitle("Security"),
          _settingTile(
            icon: Icons.lock,
            title: "Change Password",
            onTap: changePasswordDialog,
          ),

          const SizedBox(height: 16),

          _sectionTitle("Preferences"),

          ValueListenableBuilder<bool>(
            valueListenable: isDarkMode,
            builder: (context, value, _) {
              return SwitchListTile(
                value: value,
                title: const Text("Dark Mode"),
                secondary: const Icon(Icons.dark_mode),
                onChanged: (val) {
                  isDarkMode.value = val;
                  ThemePref.save(val);
                },
              );
            },
          ),

          SwitchListTile(
            value: notificationsEnabled,
            title: const Text("Notifications"),
            secondary: const Icon(Icons.notifications),
            onChanged: (value) {
              setState(() => notificationsEnabled = value);
            },
          ),

          const SizedBox(height: 16),

          _sectionTitle("System"),
          _settingTile(
            icon: Icons.delete,
            title: "Clear Cache",
            onTap: clearCache,
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: logoutDialog,
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
