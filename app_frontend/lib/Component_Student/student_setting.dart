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

  // ✅ FETCHED DATA
  String studentEmail = "";
  String studentRole = "";

  // 🔴 CONTROLLERS FOR CHANGE PASSWORD
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStudentDetails();
  }

  // 🔵 GET STUDENT DETAILS API
  Future<void> fetchStudentDetails() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/studentget/${widget.studentId}"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)["data"];

        setState(() {
          studentEmail = data["email"] ?? "";
          studentRole = data["role"] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Fetch Student Error: $e");
    }
  }

  // 🔴 CHANGE PASSWORD API FUNCTION
  Future<void> changePasswordApi() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      showSnack("New password and confirm password do not match");
      return;
    }

    try {
      final uri = Uri.parse(
        "http://localhost:8000/api/changepassword/${widget.studentId}",
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

      if (response.statusCode == 200) {
        showSnack("Password updated successfully");
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        Navigator.pop(context);
      } else {
        showSnack("Failed to update password");
      }
    } catch (e) {
      showSnack("Unable to connect to server");
    }
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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

  Future<void> logoutStudent() async {
    try {
      final response = await http.delete(
        Uri.parse("http://localhost:8000/api/logout/${widget.studentId}"),
      );

      if (response.statusCode == 200) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (_) {}
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
    showSnack("Cache cleared successfully");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Account"),
          _infoTile("Admin Email", studentEmail),
          _infoTile("Role", studentRole),

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
            onChanged: (value) => setState(() => notificationsEnabled = value),
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
