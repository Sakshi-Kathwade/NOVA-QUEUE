import 'package:flutter/material.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // 🔹 TOP NAVBAR
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              // 👤 Profile Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Text(
                  "S", // First letter of student name
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 👋 Welcome Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Welcome,",
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    "Student",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 🔔 Right-side actions (optional)
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      // 🧾 BODY (Empty for now)
      body: Center(
        child: Text(
          "Student Dashboard",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
