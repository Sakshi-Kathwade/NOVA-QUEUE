// ignore_for_file: use_build_context_synchronously, prefer_typing_uninitialized_variables, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '';
import 'join_queue.dart';
import 'my_current_queue.dart';
import 'queue_history.dart';
import 'student_setting.dart';
import 'student_waiting.dart';
import '../services/language_service.dart';
import '../services/translations.dart';
import 'edit_student_profile_screen.dart';
class QueueStatusScreen extends StatefulWidget {
  final String studentId;

  const QueueStatusScreen({super.key, required this.studentId});

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isLoading = true;
  Map<String, dynamic>? queueData;
  String errorMsg = "";

  String studentEmail = "";
  String? _studentProfilePictureUrl; // NEW: Student profile picture URL
  String currentLanguage = 'english'; // Initial value

  @override
  void initState() {
    super.initState();
    _loadLanguage(); // Load user's language preference
    fetchQueueStatus();
    fetchStudentDetails();
  }

  // ✅ Load user's language preference
  Future<void> _loadLanguage() async {
    final lang = await LanguageService.getLanguage(widget.studentId);
    setState(() {
      currentLanguage = lang;
    });
  }

  // 🔵 FETCH STUDENT DETAILS
  Future<void> fetchStudentDetails() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/student/profile/${widget.studentId}"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)["student"];
        setState(() {
          studentName = data["name"] ?? "";
          studentEmail = data["email"] ?? "";
          _studentProfilePictureUrl = data['profilePicture']; // Set profile picture URL
        });
      }
    } catch (e) {
      debugPrint("Student fetch error: $e");
    }
  }

  Future<void> fetchQueueStatus() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/queue"),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["data"] != null &&
          data["data"].isNotEmpty) {
        setState(() {
          queueData = data["data"][0];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMsg = "No queue available";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = "Server not reachable";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      // 🔹 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text("QueueNova – Student"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No new notifications")),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_circle,
              size: 35,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'edit_profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditStudentProfileScreen(
                      studentId: widget.studentId,
                    ),
                  ),
                );
              } else if (value == 'logout') {
                logoutStudent(); // 🔴 LOGOUT CALLED HERE
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                enabled: false, // Make this item non-clickable
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundImage: _studentProfilePictureUrl != null
                        ? NetworkImage("http://localhost:8000/" + _studentProfilePictureUrl!) as ImageProvider
                        : const AssetImage('assets/default_profile.png'),
                    child: _studentProfilePictureUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    studentName.isNotEmpty ? studentName : Translations.translate('student', currentLanguage),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(Translations.translate('view_profile', currentLanguage)),
                ),
              ),
              PopupMenuItem(
                value: 'edit_profile',
                child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.deepPurple),
                  title: Text(Translations.translate('edit_profile', currentLanguage)),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text(Translations.translate('logout', currentLanguage), style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),

      // 🔹 DRAWER
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _drawerHeader(),
            _drawerItem(
              Icons.home,
              "Dashboard",
              screen: QueueStatusScreen(studentId: widget.studentId),
            ),
            _drawerItem(
              Icons.add_circle_outline,
              "Join Queue",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        JoinQueueScreen(studentId: widget.studentId),
                  ),
                );
              },
            ),
            _drawerItem(
              Icons.access_time,
              "My Current Queue",
              screen: MyCurrentQueueScreen(
                queueName: queueData?["queueName"] ?? "",

                studentId: widget.studentId,
              ),
            ),
            _drawerItem(
              Icons.history,
              "Queue History",
              screen: const QueueHistoryScreen(),
            ),
            _drawerItem(
              Icons.settings,
              "Settings",
              screen: StudentSettingScreen(studentId: widget.studentId),
            ),
          ],
        ),
      ),

      // 🔹 BODY
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentWaiting(
                          queueName: queueData?["queueName"] ?? "",
                          studentId: widget.studentId,
                        ),
                      ),
                    );
                  },
                  child: const _InfoCard(
                    title: "Student Waiting",
                    value: "--",
                    icon: Icons.people,
                    color: Colors.orange,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyCurrentQueueScreen(
                          queueName: queueData?["queueName"] ?? "",
                          studentId: widget.studentId,
                        ),
                      ),
                    );
                  },
                  child: const _InfoCard(
                    title: "Current Token",
                    value: "--",
                    icon: Icons.confirmation_number,
                    color: Colors.blue,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyCurrentQueueScreen(
                          queueName: queueData?["queueName"] ?? "",
                          studentId: widget.studentId,
                        ),
                      ),
                    );
                  },
                  child: const _InfoCard(
                    title: "Completed Today",
                    value: "--",
                    icon: Icons.check_circle,
                    color: Colors.purple,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyCurrentQueueScreen(
                          queueName: queueData?["queueName"] ?? "",
                          studentId: widget.studentId,
                        ),
                      ),
                    );
                  },
                  child: const _InfoCard(
                    title: "Pending Today",
                    value: "--",
                    icon: Icons.pending_actions,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _drawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(color: Colors.deepPurple),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: _studentProfilePictureUrl != null
                ? NetworkImage("http://localhost:8000/" + _studentProfilePictureUrl!) as ImageProvider
                : const AssetImage('assets/default_profile.png'),
            child: _studentProfilePictureUrl == null
                ? const Icon(Icons.person, color: Colors.deepPurple)
                : null,
          ),
          const SizedBox(width: 12),

          // ✅ FIX: Expanded added to prevent overflow
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName.isNotEmpty ? studentName : "Student",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  studentEmail.isNotEmpty
                      ? studentEmail
                      : "email@university.com",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListTile _drawerItem(
    IconData icon,
    String title, {
    Widget? screen,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap:
          onTap ??
          () {
            Navigator.pop(context);
            if (screen != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
            }
          },
    );
  }
}

// 🔹 INFO CARD
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// 🔹 PROFILE SCREEN
class StudentProfileScreen extends StatelessWidget {
  final String studentId;

  const StudentProfileScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          "Student ID: $studentId",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
