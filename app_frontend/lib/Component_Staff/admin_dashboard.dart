import 'package:flutter/material.dart';

import 'queue_status.dart';
import 'students_waiting.dart';
import 'current_student.dart';
import 'completed_today.dart';
import 'create_queue.dart';
import 'manage_queue.dart';
import 'current_token.dart';
import 'report.dart';
import 'admin_setting.dart';

class AdminDashboard extends StatelessWidget {
  AdminDashboard({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,

        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "SmartQueue – Staff",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Counter 2 – Admin Office",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.pop(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text("John Doe"),
                  subtitle: Text("Staff"),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text("Logout"),
                ),
              ),
            ],
          ),
        ],
      ),

      // ---------------- DRAWER ----------------
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "John Doe",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    "Staff Member",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            _drawerItem(context, Icons.dashboard, "Dashboard"),
            _drawerItem(
              context,
              Icons.add_circle_outline,
              "Create Queue",
              screen: CreateQueueScreen(),
            ),
            _drawerItem(
              context,
              Icons.list_alt,
              "Manage Queue",
              screen: ManageQueueScreen(),
            ),
            _drawerItem(
              context,
              Icons.person_pin_circle,
              "Current Student",
              screen: CurrentStudentScreen(),
            ),
            _drawerItem(
              context,
              Icons.bar_chart,
              "Reports",
              screen: ReportScreen(),
            ),
            _drawerItem(
              context,
              Icons.settings,
              "Settings",
              screen: AdminSettingScreen(),
            ),

            _drawerItem(context, Icons.logout, "Logout"),
          ],
        ),
      ),

      // ---------------- BODY ----------------
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
              title: "Queue Status",
              value: "Open",
              icon: Icons.lock_open,
              color: Colors.green,
              navigateTo: QueueStatusScreen(),
            ),
            _dashboardCard(
              context: context,
              title: "Students Waiting",
              value: "12",
              icon: Icons.people,
              color: Colors.orange,
              navigateTo: StudentsWaitingScreen(),
            ),
            _dashboardCard(
              context: context,
              title: "Current Token",
              value: "A-07",
              icon: Icons.confirmation_number,
              color: Colors.blue,
              navigateTo: CurrentTokenScreen(),
            ),
            _dashboardCard(
              context: context,
              title: "Completed Today",
              value: "38",
              icon: Icons.check_circle,
              color: Colors.purple,
              navigateTo: CompletedTodayScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- DRAWER ITEM ----------------
  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title, {
    Widget? screen,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
    );
  }

  // ---------------- DASHBOARD CARD ----------------
  Widget _dashboardCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    Widget? navigateTo,
  }) {
    return InkWell(
      onTap: () {
        if (navigateTo != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => navigateTo),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
