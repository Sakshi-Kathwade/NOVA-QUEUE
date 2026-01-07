// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'join_queue.dart';
import 'my_current_queue.dart';
import 'queue_history.dart';
import 'student_setting.dart';
import 'student_waiting.dart';

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

  @override
  void initState() {
    super.initState();
    fetchQueueStatus();
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

  // 🔴 LOGOUT FUNCTION (ADDED)
  Future<void> logoutStudent() async {
    try {
      final response = await http.delete(
        Uri.parse("http://localhost:8000/api/logout/${widget.studentId}"),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Logout successfully")));

        // ⏩ Go back to Login/Home screen
        Navigator.popUntil(context, (route) => route.isFirst);
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
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StudentProfileScreen(studentId: widget.studentId),
                  ),
                );
              } else if (value == 'logout') {
                logoutStudent(); // 🔴 LOGOUT CALLED HERE
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    "Student",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("View Profile"),
                  trailing: Icon(Icons.edit, size: 18),
                ),
              ),
              PopupMenuItem(
                value: 'edit_picture',
                child: ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.deepPurple),
                  title: Text("Edit Profile Picture"),
                ),
              ),
              PopupMenuItem(
                value: 'edit_profile',
                child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.deepPurple),
                  title: Text("Edit Profile"),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text("Logout", style: TextStyle(color: Colors.red)),
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
              screen: const AdminSettingScreen(),
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
                        builder: (context) => StudentWaitingScreen(
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
    return const DrawerHeader(
      decoration: BoxDecoration(color: Colors.deepPurple),
      child: Row(
        children: [
          CircleAvatar(radius: 30, child: Icon(Icons.person)),
          SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Student",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "queue@university.com",
                style: TextStyle(color: Colors.white70),
              ),
            ],
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
