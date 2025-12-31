import 'dart:convert';
import 'package:app_frontend/Component_Student/student_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'join_queue.dart';
import 'my_current_queue.dart';
import 'queue_history.dart';
import 'student_setting.dart';
import 'student_waiting.dart';

class QueueStatusScreen extends StatefulWidget {
  const QueueStatusScreen({super.key});

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
        title: const Text("QueueNova – Student"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, size: 30),
            itemBuilder: (context) => const [
              PopupMenuItem(
                enabled: false,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    "Sakshi Kathawde",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Student"),
                ),
              ),
              PopupMenuDivider(),
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
              screen: const QueueStatusScreen(),
            ),
            _drawerItem(
              Icons.add_circle_outline,
              "Join Queue",
              screen: const JoinQueueScreen(queues: []),
            ),
            _drawerItem(
              Icons.access_time,
              "My Current Queue",
              screen: const MyCurrentQueueScreen(queueName: ''),
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
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentWaitingScreen(
                          queueName: 'selectedQueue!',
                        ),
                      ),
                    );
                  },
                  child: const _InfoCard(
                    title: "Students Waiting",
                    value: "0",
                    icon: Icons.people,
                    color: Colors.orange,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyCurrentQueueScreen(
                          queueName: 'Addmission queue',
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
                const _InfoCard(
                  title: "Completed Today",
                  value: "0",
                  icon: Icons.check_circle,
                  color: Colors.purple,
                ),
                const _InfoCard(
                  title: "Pending Today",
                  value: "0",
                  icon: Icons.pending_actions,
                  color: Colors.red,
                ),
              ],
            ),
    );
  }

  // 🔹 DRAWER HEADER
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
                "Sakshi Kathawde",
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

  // 🔹 DRAWER ITEM
  ListTile _drawerItem(IconData icon, String title, {Widget? screen}) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(context);
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
