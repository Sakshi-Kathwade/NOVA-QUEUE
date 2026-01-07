// ignore_for_file: unused_import, undefined_hidden_name, use_build_context_synchronously

import 'package:app_frontend/Component_Staff/admin_dashboard.dart';
import 'package:app_frontend/screen/home.dart';
import 'package:flutter/material.dart';
import '../Component_Staff/queue_status.dart' hide QueueStatusScreen;
import '../main.dart' show isDarkMode;
import 'package:app_frontend/Component_Staff/theme_pref.dart';
import 'student_dashboard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentSettingScreen extends StatefulWidget {
  final String studentId;

  const StudentSettingScreen({super.key, required this.studentId});

  @override
  State<StudentSettingScreen> createState() => _StudentSettingScreenState();
}

class _StudentSettingScreenState extends State<StudentSettingScreen> {
  bool notificationsEnabled = true;

  // 🔴 CONTROLLERS FOR CHANGE PASSWORD
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // 🔴 CHANGE PASSWORD API FUNCTION
  Future<void> changePasswordApi() async {
    // 🔒 Frontend validation
    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New password and confirm password do not match"),
        ),
      );
      return;
    }

    try {
      // ✅ CHANGE BASE URL ACCORDING TO DEVICE
      final uri = Uri.parse(
        "http://localhost:8000/api/changepassword/${widget.studentId}",
        // For real device use: http://YOUR_PC_IP:8000
      );

      final response = await http.put(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "currentPassword": currentPasswordController.text.trim(),
          "password": newPasswordController.text.trim(),
          "confirmPassword": confirmPasswordController.text.trim(),
        }),
      );

      // ✅ SAFE JSON DECODING
      Map<String, dynamic> responseBody = {};
      if (response.body.isNotEmpty) {
        responseBody = jsonDecode(response.body);
      }

      // ✅ SUCCESS
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully")),
        );

        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();

        Navigator.pop(context);
        return;
      }

      // ❌ ERROR HANDLING FROM BACKEND
      final message = responseBody["message"] ?? "";

      switch (message) {
        case "PASSWORD_MISMATCH":
          showSnack("Password mismatch");
          break;

        case "WEAK_PASSWORD":
          showSnack(
            "Enter strong password (Min 8 chars, Upper, Lower, Number, Special)",
          );
          break;

        case "SAME_AS_OLD_PASSWORD":
          showSnack("New password cannot be same as old password");
          break;

        case "INVALID_CURRENT_PASSWORD":
          showSnack("Current password is incorrect");
          break;

        default:
          showSnack("Failed to update password");
      }
    } catch (e) {
      // 🔥 REAL SERVER ERROR
      showSnack("Unable to connect to server");
      debugPrint("Change Password Error: $e");
    }
  }

  // ✅ COMMON SNACKBAR METHOD
  void showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 🔴 CHANGE PASSWORD DIALOG (UI UNCHANGED)
  void changePasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Current Password"),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm New Password",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: changePasswordApi,
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // 🔴 LOGOUT API
  Future<void> logoutStudent() async {
    try {
      final response = await http.delete(
        Uri.parse("http://localhost:8000/api/logout/${widget.studentId}"),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Logout successfully")));

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Logout failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error during logout")),
      );
    }
  }

  // 🔴 LOGOUT CONFIRMATION
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
            onPressed: () async {
              Navigator.pop(context);
              await logoutStudent();
            },
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
                builder: (context) => const QueueStatusScreen(studentId: ''),
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

class StudentDashboardScreen {
  const StudentDashboardScreen();
}
