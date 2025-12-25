import 'package:flutter/material.dart';

// ✅ Global Dark Mode notifier
ValueNotifier<bool> isDarkMode = ValueNotifier(false);

class AdminSettingScreen extends StatefulWidget {
  const AdminSettingScreen({super.key});

  @override
  State<AdminSettingScreen> createState() => _AdminSettingScreenState();
}

class _AdminSettingScreenState extends State<AdminSettingScreen> {
  bool notificationsEnabled = true;

  // 🔹 Change Password Dialog
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Password changed successfully")),
              );
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // 🔹 Logout Confirmation
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
            onPressed: () {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out successfully")),
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  // 🔹 Clear Cache (Demo)
  void clearCache() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Cache cleared successfully")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Account Section
          _sectionTitle("Account"),
          _infoTile("Admin Email", "admin@college.com"),
          _infoTile("Role", "Administrator"),

          const SizedBox(height: 16),

          // 🔹 Security Section
          _sectionTitle("Security"),
          _settingTile(
            icon: Icons.lock,
            title: "Change Password",
            onTap: changePasswordDialog,
          ),

          const SizedBox(height: 16),

          // 🔹 Preferences Section
          _sectionTitle("Preferences"),
          ValueListenableBuilder(
            valueListenable: isDarkMode,
            builder: (context, bool value, _) {
              return SwitchListTile(
                value: value,
                title: const Text("Dark Mode"),
                secondary: const Icon(Icons.dark_mode),
                onChanged: (val) {
                  isDarkMode.value = val;
                },
              );
            },
          ),
          SwitchListTile(
            value: notificationsEnabled,
            title: const Text("Notifications"),
            secondary: const Icon(Icons.notifications),
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // 🔹 System Section
          _sectionTitle("System"),
          _settingTile(
            icon: Icons.delete,
            title: "Clear Cache",
            onTap: clearCache,
          ),
          _settingTile(
            icon: Icons.help_outline,
            title: "Help & Support",
            onTap: () {},
          ),

          const SizedBox(height: 16),

          // 🔹 App Info
          _sectionTitle("About"),
          _infoTile("App Version", "1.0.0"),

          const SizedBox(height: 30),

          // 🔹 Logout Button
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

  // 🔹 Section Title Widget
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 🔹 Setting Tile Widget
  Widget _settingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // 🔹 Info Tile Widget
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
