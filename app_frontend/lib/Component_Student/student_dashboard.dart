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
import 'live_queue_student.dart';
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
  int estimatedTime = 0; // ✅ New state for Estimated Time
  int studentsAhead = 0; 
  int estimationConfigTime = 5;
  int maxStudents = 0;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    fetchQueueStatus();
    fetchStudentDetails();
    fetchMyPendingCount();
    _startPolling();
    NotificationService.initNotifications(
      widget.studentId,
    ); // ✅ Initialize Notifications
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
      fetchMyPendingCount();
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

            // ✅ Update Completed Counts
            if (data["data"] != null && data["data"]["completedCount"] != null) {
              activeCompletedCount = data["data"]["completedCount"];
            } else {
              activeCompletedCount = data["completedCount"] ?? data["completedToday"] ?? 0;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching current token: $e");
    }
  }

  Future<void> fetchMyPendingCount() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/student/pending/${widget.studentId}"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            activePendingCount = (data["data"] as List?)?.length ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching student pending count: $e");
    }
  }

  Future<void> fetchWaitingCount(String queueName) async {
    try {
      final encodedQueue = Uri.encodeComponent(queueName);
      // Fetch queue details for maxStudents
      int fetchedMax = maxStudents;
      int estConfig = estimationConfigTime;
      try {
        final qRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/queue"));
        if (qRes.statusCode == 200) {
          final qd = jsonDecode(qRes.body);
          if (qd['success'] == true && qd['data'] != null) {
            List<dynamic> queues = qd['data'];
            for (var q in queues) {
              if (q['queueName'] == queueName) {
                fetchedMax = q['maxStudents'] ?? 0;
                String adminId = q['adminId'] ?? "";
                if (adminId.isNotEmpty) {
                   final stRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/admin/settings/queue/$adminId"));
                   if (stRes.statusCode == 200) {
                      final stData = jsonDecode(stRes.body);
                      if (stData["success"] == true && stData["settings"] != null) {
                         estConfig = stData["settings"]["estimatedServiceTimePerStudent"] ?? 5;
                      }
                   }
                }
                break;
              }
            }
          }
        }
      } catch (e) {
        // ignore
      }

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/remainingtoken/$encodedQueue"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          int count = data["waitingCount"] ?? 0;
          int myTokenNum = int.tryParse(currentToken.replaceAll("A-", "")) ?? 0;
          int ahead = 0;
          
          if (data["waiting"] != null) {
            final waitingList = data["waiting"] as List;
            for (var w in waitingList) {
              int tNum = w["tokenNumber"] ?? 0;
              if (myTokenNum > 0 && tNum > 0 && tNum < myTokenNum) {
                ahead++;
              }
            }
          }
          if (myTokenNum == 0) ahead = count;
          
          int calcEst = ahead * estConfig;

          if (mounted) {
            setState(() {
              waitingCount = count;
              maxStudents = fetchedMax;
              estimationConfigTime = estConfig;
              studentsAhead = ahead;
              if (calcEst > 0) {
                 estimatedTime = calcEst;
              }
            });
          }
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
            estimatedTime = data["estimatedWaitingTime"] ?? 0;
          });
          return true; // Token found
        }
      } else {
        setState(() {
          currentToken = "--";
          estimatedTime = 0;
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // 🔹 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "NovaQueue – ${Translations.translate('student', currentLanguage)}",
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    Translations.translate(
                      'no_new_notifications',
                      currentLanguage,
                    ),
                  ),
                ),
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
                    Translations.translate('Student', currentLanguage),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'edit_profile',
                child: ListTile(
                  leading: Icon(
                    Icons.edit,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.deepPurpleAccent
                        : Colors.deepPurple,
                  ),
                  title: Text(
                    Translations.translate('Edit Profile', currentLanguage),
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _drawerHeader(),
            _drawerItem(
              Icons.home,
              Translations.translate('dashboard', currentLanguage),
              screen: QueueStatusScreen(studentId: widget.studentId),
            ),
            _drawerItem(
              Icons.add_circle_outline,
              Translations.translate('Join Queue', currentLanguage),
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
              Translations.translate('My Token', currentLanguage),
              screen: MyCurrentQueueScreen(
                queueName: queueData?["queueName"] ?? "",

                studentId: widget.studentId,
              ),
            ),
            _drawerItem(
              Icons.history,
              Translations.translate('history', currentLanguage),
              screen: QueueHistoryScreen(studentId: widget.studentId),
            ),
            _drawerItem(
              Icons.settings,
              Translations.translate('settings', currentLanguage),
              screen: StudentSettingScreen(studentId: widget.studentId),
            ),
            _drawerItem(
              Icons.info_outline,
              Translations.translate('About', currentLanguage),
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
                        builder: (context) => LiveQueueStudent(
                          queueName: queueData?["queueName"] ?? "",
                          studentId: widget.studentId,
                        ),
                      ),
                    );
                  },
                  child: _InfoCard(
                    title: Translations.translate(
                      'live_queue',
                      currentLanguage,
                    ),
                    value: nowServingToken != "--" ? nowServingToken : (maxStudents > 0 ? maxStudents.toString() : "--"),
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
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                        Text(
                          Translations.translate('my Token', currentLanguage),
                          textAlign: TextAlign.center,
                        ),
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
                    title: Translations.translate(
                      'pending_today',
                      currentLanguage,
                    ),
                    value: activePendingCount.toString(),
                    icon: Icons.hourglass_empty,
                    color: Colors.teal,
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
                    title: Translations.translate(
                      'completed_today',
                      currentLanguage,
                    ),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
        ),
      ),
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
                  studentName.isNotEmpty ? studentName : "—",
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
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
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
      leading: Icon(
        icon,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.deepPurpleAccent
            : Colors.deepPurple,
      ),
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
      color: Theme.of(context).cardColor,
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
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
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
