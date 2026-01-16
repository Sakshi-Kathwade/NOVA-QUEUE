// ignore_for_file: use_build_context_synchronously, prefer_interpolation_to_compose_strings

import 'package:app_frontend/Component_Staff/admin_dashboard.dart';
import 'package:flutter/material.dart';
import '../main.dart' show isDarkMode;
import 'theme_pref.dart';
import '../screen/login.dart';
import '../screen/home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/language_service.dart';
import '../services/translations.dart';

class AdminSettingScreen extends StatefulWidget {
  final String? adminEmail;
  final String? adminId;
  final VoidCallback? onLanguageChanged; // ✅ Callback when language changes

  const AdminSettingScreen({
    super.key,
    this.adminEmail,
    this.adminId,
    this.onLanguageChanged,
  });

  @override
  State<AdminSettingScreen> createState() => _AdminSettingScreenState();
}

class _AdminSettingScreenState extends State<AdminSettingScreen> {
  bool notificationsEnabled = true;
  String currentLanguage = 'english';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  // ✅ Load user's language preference
  Future<void> _loadLanguage() async {
    if (widget.adminId != null) {
      final lang = await LanguageService.getLanguage(widget.adminId!);
      setState(() {
        currentLanguage = lang;
      });
    }
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
        if (widget.adminId != null) {
          await LanguageService.setLanguage(widget.adminId!, langCode);
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
        }
      },
    );
  }

  // ✅ Controllers for change password
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ CHANGE PASSWORD API
  Future<void> changePasswordApi() async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Validation
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.translate('all_fields_required', currentLanguage)),
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.translate('passwords_do_not_match', currentLanguage)),
        ),
      );
      return;
    }

    try {
      final response = await http.put(
        Uri.parse(
          "http://localhost:8000/api/adminchangepassword/${widget.adminId ?? ''}",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "currentPassword": currentPassword,
          "password": newPassword,
          "confirmPassword": confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translations.translate('password_changed_successfully', currentLanguage)),
          ),
        );
        // Clear controllers
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to change password"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error. Please try again.")),
      );
    }
  }

  void changePasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(Translations.translate('change_password', currentLanguage)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: Translations.translate('current_password', currentLanguage),
              ),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: Translations.translate('new_password', currentLanguage),
              ),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: Translations.translate('confirm_new_password', currentLanguage),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              currentPasswordController.clear();
              newPasswordController.clear();
              confirmPasswordController.clear();
            },
            child: Text(Translations.translate('cancel', currentLanguage)),
          ),
          ElevatedButton(
            onPressed: changePasswordApi,
            child: Text(Translations.translate('update', currentLanguage)),
          ),
        ],
      ),
    );
  }

  // ✅ LOGOUT FUNCTION - Delete admin account
  Future<void> performLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(Translations.translate('logout_delete_account', currentLanguage)),
        content: Text(
          Translations.translate('logout_delete_account', currentLanguage) + 
          " - This will permanently delete your admin account from the database. "
          "You will need to create a new account to login again. "
          "Are you sure you want to proceed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Translations.translate('cancel', currentLanguage)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              Translations.translate('delete_logout', currentLanguage),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && widget.adminId != null) {
      try {
        // ✅ Delete admin account from database
        final response = await http.delete(
          Uri.parse("http://localhost:8000/api/deleteadmin/${widget.adminId}"),
          headers: {"Content-Type": "application/json"},
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Admin account deleted successfully. Logged out."),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to home screen (which has login button)
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

          // Fallback: Navigate to login screen directly
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ?? "Failed to delete admin account",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Server error. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void logoutDialog() {
    performLogout();
  }

  void clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(Translations.translate('cache_cleared_successfully', currentLanguage)),
      ),
    );
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
                builder: (context) => AdminDashboard(
                  adminEmail: widget.adminEmail,
                  adminId: widget.adminId,
                ),
              ),
            );
          },
        ),
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
            widget.adminEmail ?? "admin@college.com",
          ),
          _infoTile(
            Translations.translate('role', currentLanguage),
            Translations.translate('administrator', currentLanguage),
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
            onChanged: (value) {
              setState(() => notificationsEnabled = value);
            },
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
