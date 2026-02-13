// ignore_for_file: use_build_context_synchronously, unnecessary_brace_in_string_interps, prefer_interpolation_to_compose_strings, duplicate_import

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

import 'manage_queue.dart';
import 'queue_status.dart';
import 'completed_today.dart';
import 'create_queue.dart';

import 'current_token.dart';

import 'admin_setting.dart';
import '../services/translations.dart';
import 'edit_admin_profile_screen.dart';
import 'pending_student.dart';
import 'waiting_card.dart';
import 'queue_preview.dart';
import 'admin_live_queue.dart';
import 'admin_history.dart';
import '../screen/login.dart';
import '../screen/home.dart';
import '../services/language_service.dart';
import '../services/translations.dart';

class AdminDashboard extends StatefulWidget {
  final String? adminEmail; // ✅ Store admin email
  final String? adminId; // ✅ Store admin ID

  const AdminDashboard({super.key, this.adminEmail, this.adminId});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// ✅ dynamic queue name - no hardcoded fallback
  String? queueName;
  String? queueId; // ✅ Queue ID for status updates
  String? adminEmail; // ✅ Admin email state
  String? adminId; // ✅ Admin ID state
  Timer? _pollTimer; // ✅ Timer for real-time updates
  Timer? _queuePollTimer; // ✅ Timer for queue refresh

  // Real-time update state
  int waitingCount = 0;
  String currentToken = "N/A";
  int completedToday = 0;
  int pendingCount = 0; // ✅ Pending student count
  String queueStatus = "N/A"; // ✅ Dynamic queue status (Active/Inactive)
  int averageWaitingTime = 0; // ✅ Average waiting time in minutes
  List<dynamic> liveQueueData = []; // ✅ Live queue data from backend
  String currentLanguage =
      'english'; // ✅ Current language (english/hindi/marathi)
  String? _adminName; // ✅ Admin name fetched from backend
  String? _adminProfilePictureUrl; // Admin profile picture URL
  String? _adminRole; // Admin role fetched from backend
  String? startTime; // ✅ Start time of the queue
  String? endTime; // ✅ End time of the queue

  int? maxStudents; // ✅ Max students for progress bar
  Timer? _expireCheckTimer; // ✅ Timer to check for queue expiry

  @override
  void initState() {
    super.initState();
    adminEmail = widget.adminEmail; // ✅ Store admin email
    adminId = widget.adminId; // ✅ Store admin ID
    _loadLanguage(); // ✅ Load user's language preference
    _fetchAdminProfilePicture(); // Fetch admin profile picture and role
    fetchQueueName(); // ✅ Fetch active queue first
    fetchDashboardData(); // ✅ Initial data fetch (after queue is fetched)
    fetchLiveQueueData(); // ✅ Fetch live queue data
    startPolling(); // ✅ Start real-time polling
    startQueuePolling(); // ✅ Start queue polling to detect changes
    startExpiryCheck(); // ✅ Start expiry check
  }

  // Fetch admin profile picture and role from backend
  Future<void> _fetchAdminProfilePicture() async {
    if (adminId == null) return;
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/profile/${adminId}"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['admin'] != null) {
          setState(() {
            _adminName = data['admin']['name']; // ✅ Store admin name
            adminEmail = data['admin']['email']; // ✅ Update email if changed
            _adminProfilePictureUrl = data['admin']['profilePicture'];
            _adminRole = data['admin']['role'] ?? 'Admin';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching admin profile: $e");
    }
  }

  // ✅ Load user's language preference
  Future<void> _loadLanguage() async {
    if (adminId != null) {
      final lang = await LanguageService.getLanguage(adminId!);
      setState(() {
        currentLanguage = lang;
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel(); // ✅ Clean up timer
    _queuePollTimer?.cancel(); // ✅ Clean up queue timer
    _expireCheckTimer?.cancel(); // ✅ Clean up expiry timer
    super.dispose();
  }

  /// ✅ FETCH ACTIVE QUEUE FROM BACKEND (fully dynamic)
  Future<void> fetchQueueName() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/activequeue/$adminId"),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData["success"] == true && jsonData["queueName"] != null) {
          final newQueueName = jsonData["queueName"] as String;
          final queueData = jsonData["data"];

          // Check if queue is expired
          bool isExpired = false;
          if (queueData != null && queueData["endTime"] != null) {
             final end = DateTime.parse(queueData["endTime"]).toLocal();
             if (DateTime.now().isAfter(end)) {
               isExpired = true;
             }
          }

          if (isExpired) {
             setState(() {
              queueName = null;
              queueId = null;
              queueStatus = "N/A";
              liveQueueData = [];
              maxStudents = null;
             });
             return;
          }

          // ✅ Only update if queue name changed (to avoid unnecessary rebuilds)
          if (queueName != newQueueName) {
            setState(() {
              queueName = newQueueName;
              queueId = queueData != null && queueData["_id"] != null
                  ? queueData["_id"] as String
                  : null;
              // ✅ Fetch queue status dynamically
              queueStatus = queueData != null && queueData["status"] != null
                  ? queueData["status"] as String
                  : "N/A";
              
              // ✅ Fetch max students
              if (queueData != null && queueData["maxStudents"] != null) {
                 maxStudents = queueData["maxStudents"] is int 
                    ? queueData["maxStudents"] 
                    : int.tryParse(queueData["maxStudents"].toString());
              }

              // ✅ Fetch start and end times
              if (queueData != null &&
                  queueData["startTime"] != null &&
                  queueData["endTime"] != null) {
                try {
                  final start = DateTime.parse(
                    queueData["startTime"],
                  ).toLocal();
                  final end = DateTime.parse(queueData["endTime"]).toLocal();
                  String format(DateTime dt) {
                    int hour = dt.hour;
                    String ampm = hour >= 12 ? "PM" : "AM";
                    hour = hour % 12;
                    if (hour == 0) hour = 12;
                    return "${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm";
                  }

                  startTime = format(start);
                  endTime = format(end);
                } catch (e) {
                  startTime = null;
                  endTime = null;
                }
              } else {
                startTime = null;
                endTime = null;
              }
            });

            // ✅ Refresh dashboard data when queue changes
            fetchDashboardData();
            fetchLiveQueueData(); // ✅ Fetch live queue data
          } else {
            // ✅ Update status even if queue name hasn't changed
            if (queueData != null && queueData["status"] != null) {
              final newStatus = queueData["status"] as String;
              if (queueStatus != newStatus) {
                setState(() {
                  queueStatus = newStatus;
                });
              }
            }
          }
        }
      } else {
        // No queue found (success: false) - set to null
        setState(() {
          queueName = null;
          queueId = null;
          queueStatus = "N/A";
          liveQueueData = [];
          maxStudents = null;
        });
      }
    } catch (e) {
      // Silent fail – will retry on next poll
      debugPrint("Error fetching queue: $e");
    }
  }

  /// ✅ Start polling for queue changes (every 5 seconds)
  void startQueuePolling() {
    _queuePollTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchQueueName();
    });
  }

  /// ✅ Start expiry check (every 30 seconds)
  void startExpiryCheck() {
    _expireCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (queueName != null) {
        // Force refresh to check expiry
        fetchQueueName();
      }
    });
  }

  /// ✅ REAL-TIME: Fetch dashboard data (waiting count, current token, completed today)
  Future<void> fetchDashboardData() async {
    // ✅ If no active queue, reset data
    if (queueName == null || queueName!.isEmpty) {
        setState(() {
          waitingCount = 0;
          currentToken = "N/A";
          completedToday = 0;
          pendingCount = 0; // Reset pending as well if queue is finished
          averageWaitingTime = 0;
        });
      return;
    }

    try {
      // Fetch waiting count
      // count
      final waitingResponse = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/remainingtoken/$queueName"),
      );

      if (waitingResponse.statusCode == 200) {
        final waitingData = json.decode(waitingResponse.body);
        final waitingList = (waitingData["waiting"] as List?) ?? [];
        setState(() {
          waitingCount = waitingList.length;
          // ✅ Calculate average waiting time: tokens ahead * 5 minutes per token
          averageWaitingTime = waitingCount * 5;
        });
      }

      // Fetch current token
      final tokenResponse = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/currenttoken/$queueName"),
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = json.decode(tokenResponse.body);
        if (tokenData["data"] != null) {
          final tokenNumber = tokenData["data"]["tokenNumber"] ?? 0;
          final completedCount = tokenData["data"]["completedCount"] ?? 0;
          final pCount = tokenData["data"]["pendingCount"] ?? 0;
          setState(() {
            currentToken = tokenNumber > 0 ? "A-$tokenNumber" : "N/A";
            completedToday = completedCount;
            pendingCount = pCount;
          });
        } else {
          setState(() {
            currentToken = "N/A";
            completedToday = 0;
            pendingCount = 0;
          });
        }
      }
    } catch (e) {
      // Silent fail - data will refresh on next poll
      debugPrint("Error fetching dashboard data: $e");
    }
  }

  /// ✅ FETCH LIVE QUEUE DATA FROM BACKEND
  Future<void> fetchLiveQueueData() async {
    if (queueName == null || queueName!.isEmpty) {
      setState(() {
        liveQueueData = [];
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/remainingtoken/$queueName"),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final waitingList = (jsonData["waiting"] as List?) ?? [];

        // ✅ Transform data for LiveQueuePreviewScreen
        final transformedData = waitingList.map<Map<String, String>>((item) {
          final tokenNumber = item["tokenNumber"] ?? 0;
          final studentName = item["studentName"] ?? "Unknown";
          return {"name": studentName, "token": "A-$tokenNumber"};
        }).toList();

        setState(() {
          liveQueueData = transformedData;
        });
      }
    } catch (e) {
      debugPrint("Error fetching live queue data: $e");
      setState(() {
        liveQueueData = [];
      });
    }
  }

  /// ✅ REAL-TIME: Start polling for updates every 3 seconds
  void startPolling() {
    _pollTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      fetchDashboardData();
      fetchLiveQueueData(); // ✅ Also refresh live queue data
    });
  }

  /// ✅ LOGOUT: Delete admin account and redirect to login
  Future<void> performLogout() async {
    // Cancel polling
    _pollTimer?.cancel();

    // Show confirmation dialog with warning about account deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout & Delete Account"),
        content: const Text(
          "This will permanently delete your admin account from the database. "
          "You will need to create a new account to login again. "
          "Are you sure you want to proceed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete & Logout",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && adminId != null) {
      // Cancel all timers
      _queuePollTimer?.cancel();

      try {
        // ✅ Delete admin account from database
        final response = await http.delete(
          Uri.parse("${ApiConfig.baseUrl}/deleteadmin/$adminId"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 2,

        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "QueueNova",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              queueName != null
                  ? queueName!
                  : Translations.translate(
                      'no_active_queue',
                      currentLanguage,
                    ),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),

        /// ✅ ADDED: NOTIFICATION + PROFILE
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {},
          ),

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_circle,
              size: 34,
              color: Colors.white,
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await performLogout(); // ✅ Call logout function
              } else if (value == 'edit_profile' && adminId != null) {
                // ✅ Wait for result and refresh profile
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditAdminProfileScreen(
                      adminId: adminId,
                      adminEmail: adminEmail,
                    ),
                  ),
                );
                _fetchAdminProfilePicture(); // ✅ Refresh profile after return
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
                        _adminProfilePictureUrl != null &&
                            _adminProfilePictureUrl!.isNotEmpty
                        ? NetworkImage(
                                "http://localhost:8000" +
                                    _adminProfilePictureUrl!,
                              )
                              as ImageProvider
                        : null,
                    child:
                        _adminProfilePictureUrl == null ||
                            _adminProfilePictureUrl!.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    _adminName ??
                        adminEmail ??
                        "Admin", // ✅ Display Name if available
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    Translations.translate('staff_member', currentLanguage),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'edit_profile',
                child: ListTile(
                  leading: const Icon(Icons.edit, color: Colors.deepPurple),
                  title: Text(
                    Translations.translate('edit_profile', currentLanguage),
                  ),
                ),
              ),
              PopupMenuDivider(),
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

      // ================= DRAWER =================
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
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
                        _adminProfilePictureUrl != null &&
                            _adminProfilePictureUrl!.isNotEmpty
                        ? NetworkImage(
                                "http://localhost:8000" +
                                    _adminProfilePictureUrl!,
                              )
                              as ImageProvider
                        : null,
                    child:
                        _adminProfilePictureUrl == null ||
                            _adminProfilePictureUrl!.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 35,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _adminRole != null
                              ? (_adminRole!.toLowerCase() == 'admin'
                                    ? Translations.translate(
                                        'administrator',
                                        currentLanguage,
                                      )
                                    : _adminRole!)
                              : Translations.translate(
                                  'administrator',
                                  currentLanguage,
                                ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          adminEmail ?? "Admin",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _drawerItem(
              context,
              Icons.dashboard,
              Translations.translate('dashboard', currentLanguage),
            ),
            _drawerItem(
              context,
              Icons.add,
              Translations.translate('create_queue', currentLanguage),
              screen: CreateQueueScreen(adminId: adminId),
            ),
            _drawerItem(
              context,
              Icons.person,
              Translations.translate('current_token', currentLanguage),
              screen: CurrentTokenScreen(
                queueName: queueName ?? "",
                adminId: adminId,
                maxStudents: maxStudents, // ✅ Pass maxStudents
              ),
            ),

            _drawerItem(
              context,
              Icons.bar_chart,
              Translations.translate('Manage Queue', currentLanguage),
              screen: ManageQueueScreen(adminId: adminId),
            ),

            _drawerItem(
              context,
              Icons.history,
              Translations.translate('history', currentLanguage),
              screen: AdminHistoryScreen(queueName: queueName, adminId: adminId),
            ),
            _drawerItem(
              context,
              Icons.settings,
              Translations.translate('settings', currentLanguage),
              screen: AdminSettingScreen(
                adminEmail: adminEmail,
                adminId: adminId,
                onLanguageChanged:
                    _loadLanguage, // ✅ Callback to refresh language
              ),
            ),
          ],
        ),
      ),

      // ================= BODY =================
      // ================= BODY =================
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _dashboardCard(
              context: context,
              title: Translations.translate('queue_status', currentLanguage),
              value: queueStatus == "Active"
                  ? Translations.translate('active', currentLanguage)
                  : Translations.translate('inactive', currentLanguage),
              icon: queueStatus == "Active" ? Icons.lock_open : Icons.lock,
              color: queueStatus == "Active" ? Colors.green : Colors.grey,
              navigateTo: queueId != null
                  ? QueueStatus(adminId: adminId, studentId: "studentID")
                  : null,
            ),

            _dashboardCard(
              context: context,
              title: Translations.translate(
                'students_waiting',
                currentLanguage,
              ),
              value: waitingCount.toString(),
              icon: Icons.people,
              color: Colors.orange,
              navigateTo: WaitingCardScreen(queueName: queueName ?? ""),
            ),

            _dashboardCard(
              context: context,
              title: Translations.translate('current_token', currentLanguage),
              value: currentToken,
              icon: Icons.confirmation_number,
              color: Colors.blue,
              navigateTo: CurrentTokenScreen(
                queueName: queueName ?? "",
                maxStudents: maxStudents, // ✅ Pass maxStudents
              ),
            ),

            _dashboardCard(
              context: context,
              title: Translations.translate('completed_today', currentLanguage),
              value: completedToday.toString(),
              icon: Icons.check_circle,
              color: Colors.purple,
              navigateTo: CompletedTodayScreen(
                queueName: queueName ?? "",
                adminId: adminId,
              ),
            ),

            _dashboardCard(
              context: context,
              title: Translations.translate('live_queue', currentLanguage),
              value: liveQueueData.isNotEmpty ? "${liveQueueData.length}" : "0",
              icon: Icons.people_alt,
              color: Colors.deepPurple,
              navigateTo: AdminLiveQueueScreen(
                adminId: adminId!,
                queueName: queueName ?? "",
              ),
            ),

            _dashboardCard(
              context: context,
              title: Translations.translate('pending_student', currentLanguage),
              value: pendingCount.toString(),
              icon: Icons.hourglass_empty,
              color: Colors.teal,
              navigateTo: PendingStudentsScreen(
                queueName: queueName ?? "",
                adminId: adminId!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DRAWER ITEM =================
  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title, {
    Widget? screen,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      onTap: () async {
        Navigator.pop(context);
        if (screen != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
          _fetchAdminProfilePicture(); // ✅ Refresh dashboard
        }
      },
    );
  }

  // ================= DASHBOARD CARD =================
  Widget _dashboardCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    Widget? navigateTo,
  }) {
    return InkWell(
      onTap: navigateTo == null
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => navigateTo),
              );
            },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
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
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
