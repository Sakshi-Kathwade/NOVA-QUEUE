// ignore_for_file: use_build_context_synchronously, prefer_typing_uninitialized_variables, prefer_interpolation_to_compose_strings, unnecessary_string_interpolations, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../screen/login.dart';
import '../services/api_config.dart';
import 'join_queue.dart';
import 'my_current_queue.dart';
import 'queue_history.dart';
import 'student_setting.dart';
import 'student_waiting.dart';
import '../services/notification_service.dart';
import '../services/language_service.dart';
import '../services/translations.dart';
import 'edit_student_profile_screen.dart';
import 'my_pending_today.dart';
import 'completed_today.dart';
import '../screen/about_us.dart';

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

  String studentName = "";
  String studentEmail = "";
  String studentRole = "Student";
  String? _studentProfilePictureUrl;
  String currentToken = "--";
  String nowServingToken = "--";
  int waitingCount = 0;
  String currentLanguage = 'english';
  
  int activePendingCount = 0; // ✅ New state for Pending Today
  int activeCompletedCount = 0; // ✅ New state for Completed Today
  
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    fetchQueueStatus();
    fetchQueueStatus();
    fetchStudentDetails();
    _startPolling();
    NotificationService.initNotifications(widget.studentId); // ✅ Initialize Notifications
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (queueData != null && queueData!["queueName"] != null) {
        fetchMyToken(queueData!["queueName"]);
        fetchNowServingToken(queueData!["queueName"]);
        fetchWaitingCount(queueData!["queueName"]);
      }
    });
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
        Uri.parse("${ApiConfig.baseUrl}/student/profile/${widget.studentId}"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["student"] != null) {
          final s = data["student"];
          setState(() {
            studentName = s["name"] ?? "";
            studentEmail = s["email"] ?? "";
            studentRole = s["role"] ?? "Student";
            _studentProfilePictureUrl = s['profilePicture'];
          });
        }
      }
    } catch (e) {
      debugPrint("Student fetch error: $e");
    }
  }

  Future<void> fetchQueueStatus() async {
    try {
      final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/queue"));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["data"] != null &&
          data["data"].isNotEmpty) {
        List<dynamic> queues = data["data"];
        bool tokenFound = false;

        // Iterate to find where the student has a token
        for (var q in queues) {
          String qName = q["queueName"];
          bool hasToken = await fetchMyToken(qName);
          if (hasToken) {
            setState(() {
              queueData = q;
              isLoading = false;
            });
            tokenFound = true;
            break;
          }
        }

        if (!tokenFound) {
          setState(() {
            queueData = queues[0];
            isLoading = false;
            // Clear token data
            currentToken = "--";
          });
        }
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

  Future<void> fetchNowServingToken(String queueName) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/currenttoken/$queueName"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (mounted) {
           setState(() {
              // Update Now Serving
              if (data["success"] == true && data["data"] != null) {
                nowServingToken = "A-${data["data"]["tokenNumber"]}";
              } else {
                nowServingToken = "--";
              }
              
              // ✅ Update Pending & Completed Counts
              activePendingCount = data["pendingCount"] ?? 0;
              activeCompletedCount = data["completedCount"] ?? 0;
           });
        }
      }
    } catch (e) {
      debugPrint("Error fetching current token: $e");
    }
  }

  Future<void> fetchWaitingCount(String queueName) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/remainingtoken/$queueName"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            waitingCount = data["waitingCount"] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching waiting count: $e");
    }
  }

  // Modified fetchMyToken to return success status
  Future<bool> fetchMyToken(String queueName) async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/tokenget/$queueName/${widget.studentId}",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            currentToken = data["tokenNumber"].toString();
          });
          return true; // Token found
        }
      } else {
        setState(() {
          currentToken = "--";
        });
      }
    } catch (e) {
      debugPrint("Error fetching token: $e");
    }
    return false; // Not found
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
            onSelected: (value) async {
              if (value == 'edit_profile') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditStudentProfileScreen(studentId: widget.studentId),
                  ),
                );
                fetchStudentDetails(); // ✅ Refresh profile after return
              } else if (value == 'logout') {
                logoutStudent();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                enabled: false, // Make this item non-clickable
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white24,
                    backgroundImage:
                        _studentProfilePictureUrl != null &&
                            _studentProfilePictureUrl!.isNotEmpty
                        ? NetworkImage(
                                "${ApiConfig.baseUrl.replaceAll('/api', '')}" +
                                    _studentProfilePictureUrl!,
                              )
                              as ImageProvider
                        : null,
                    child:
                        _studentProfilePictureUrl == null ||
                            _studentProfilePictureUrl!.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    studentName.isNotEmpty
                        ? studentName
                        : Translations.translate('student', currentLanguage),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    Translations.translate('view_profile', currentLanguage),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'edit_profile',
                child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.deepPurple),
                  title: Text(
                    Translations.translate('edit_profile', currentLanguage),
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    Translations.translate('logout', currentLanguage),
                    style: TextStyle(color: Colors.red),
                  ),
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
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        JoinQueueScreen(studentId: widget.studentId),
                  ),
                );
                fetchQueueStatus(); // Refresh dashboard
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
              screen: QueueHistoryScreen(studentId: widget.studentId),
            ),
            _drawerItem(
              Icons.settings,
              "Settings",
              screen: StudentSettingScreen(studentId: widget.studentId),
            ),
            _drawerItem(
              Icons.info_outline,
              "About",
              screen: const AboutUsScreen(),
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
                  child: _InfoCard(
                    title: "Students Waiting",
                    value: waitingCount > 0 ? waitingCount.toString() : "--",
                    icon: Icons.people,
                    color: Colors.orange,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (currentToken != "--") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyCurrentQueueScreen(
                            queueName: queueData?["queueName"] ?? "",
                            studentId: widget.studentId,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.confirmation_number,
                          size: 36,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentToken == "--" ? "--" : "A-$currentToken",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text("My Token", textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyPendingToday(
                          queueName: queueData?["queueName"] ?? "",
                          studentId: widget.studentId,
                        ),
                      ),
                    );
                  },
                  child: _InfoCard(
                    title: "Pending Today",
                    value: activePendingCount.toString(),
                    icon: Icons.pending_actions,
                    color: Colors.red,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompletedTodayScreen(
                          queueName: queueData?["queueName"] ?? "",
                          studentId: widget.studentId,
                        ),
                      ),
                    );
                  },
                  child: _InfoCard(
                    title: "Completed Today",
                    value: activeCompletedCount.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
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
            backgroundColor: Colors.white24,
            backgroundImage:
                _studentProfilePictureUrl != null &&
                    _studentProfilePictureUrl!.isNotEmpty
                ? NetworkImage(
                        "${ApiConfig.baseUrl.replaceAll('/api', '')}" +
                            _studentProfilePictureUrl!,
                      )
                      as ImageProvider
                : null,
            child:
                _studentProfilePictureUrl == null ||
                    _studentProfilePictureUrl!.isEmpty
                ? const Icon(Icons.person, size: 35, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentRole.isNotEmpty
                      ? (studentRole.toLowerCase() == 'student'
                            ? Translations.translate('student', currentLanguage)
                            : studentRole)
                      : Translations.translate('student', currentLanguage),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  studentName.isNotEmpty ? studentName : "—",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  studentEmail.isNotEmpty
                      ? studentEmail
                      : "email@university.com",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
          () async {
            // ✅ Async
            Navigator.pop(context);
            if (screen != null) {
              await Navigator.push(
                // ✅ Wait for return
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
              fetchStudentDetails(); // ✅ Refresh dashboard
            }
          },
    );
  }

  // 🔴 LOGOUT METHOD
  void logoutStudent() {
    // Implement your logout logic here
    // For now, let's just navigate to the login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
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
