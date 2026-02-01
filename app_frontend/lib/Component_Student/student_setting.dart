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
import '../services/language_service.dart';
import '../services/translations.dart';
import 'edit_student_profile_screen.dart'; // Import the new screen

class StudentSettingScreen extends StatefulWidget {
  final String studentId;
  final VoidCallback? onLanguageChanged; // ✅ Callback when language changes

  const StudentSettingScreen({
    super.key,
    required this.studentId,
    this.onLanguageChanged,
  });

  @override
  State<StudentSettingScreen> createState() => _StudentSettingScreenState();
}

class _StudentSettingScreenState extends State<StudentSettingScreen> {
  bool notificationsEnabled = true;
  String currentLanguage = 'english';

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
    _loadLanguage();
    fetchStudentDetails();
  }

  // ✅ Load user's language preference
  Future<void> _loadLanguage() async {
    final lang = await LanguageService.getLanguage(widget.studentId);
    setState(() {
      currentLanguage = lang;
    });
  }

  // ✅ Show language selection dialog
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.translate('select_language', currentLanguage)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption('english', 'English', '🇬🇧'),
            _languageOption('hindi', 'हिंदी', '🇮🇳'),
            _languageOption('marathi', 'मराठी', '🇮🇳'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.translate('cancel', currentLanguage)),
          ),
        ],
      ),
    );
  }

  // ✅ Language option widget
  Widget _languageOption(String langCode, String langName, String flag) {
    final isSelected = currentLanguage == langCode;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(langName),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.deepPurple)
          : null,
      onTap: () async {
        await LanguageService.setLanguage(widget.studentId, langCode);
        setState(() {
          currentLanguage = langCode;
        });
        Navigator.pop(context);
        // ✅ Refresh parent screen
        if (widget.onLanguageChanged != null) {
          widget.onLanguageChanged!();
        }
        // ✅ Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${Translations.translate('language', currentLanguage)} ${Translations.translate('save', currentLanguage)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
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
        title: Text(Translations.translate('settings', currentLanguage)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(Translations.translate('account', currentLanguage)),
          _infoTile(
            Translations.translate('admin_email', currentLanguage),
            studentEmail,
          ),
          _infoTile(
            Translations.translate('role', currentLanguage),
            studentRole,
          ),

          const SizedBox(height: 16),

          // New: Edit Student Profile
          _sectionTitle(Translations.translate('profile', currentLanguage)),
          _settingTile(
            icon: Icons.person,
            title: Translations.translate('edit_profile', currentLanguage),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditStudentProfileScreen(
                    studentId: widget.studentId,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          _sectionTitle(Translations.translate('security', currentLanguage)),
          _settingTile(
            icon: Icons.lock,
            title: Translations.translate('change_password', currentLanguage),
            onTap: changePasswordDialog,
          ),

          const SizedBox(height: 16),

          _sectionTitle(Translations.translate('preferences', currentLanguage)),
          // ✅ Language Selection
          _settingTile(
            icon: Icons.language,
            title: Translations.translate('language', currentLanguage),
            onTap: _showLanguageDialog,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isDarkMode,
            builder: (context, value, _) {
              return SwitchListTile(
                value: value,
                title: Text(Translations.translate('dark_mode', currentLanguage)),
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
            title: Text(Translations.translate('notifications', currentLanguage)),
            secondary: const Icon(Icons.notifications),
            onChanged: (value) => setState(() => notificationsEnabled = value),
          ),

          const SizedBox(height: 16),

          _sectionTitle(Translations.translate('system', currentLanguage)),
          _settingTile(
            icon: Icons.delete,
            title: Translations.translate('clear_cache', currentLanguage),
            onTap: clearCache,
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: logoutDialog,
            icon: const Icon(Icons.logout),
            label: Text(Translations.translate('logout', currentLanguage)),
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
