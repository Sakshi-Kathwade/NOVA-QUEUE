import 'package:flutter/material.dart';

class WaitingCardScreen extends StatelessWidget {
  final int remainingStudents;
  final int avgTimePerStudent; // in minutes

  const WaitingCardScreen({
    super.key,
    required this.remainingStudents,
    required this.avgTimePerStudent,
  });

  @override
  Widget build(BuildContext context) {
    int totalWaitTime = remainingStudents * avgTimePerStudent;

    // Status calculation
    String status;
    Color statusColor;

    if (totalWaitTime <= 20) {
      status = "Low Waiting";
      statusColor = Colors.green;
    } else if (totalWaitTime <= 45) {
      status = "Medium Waiting";
      statusColor = Colors.orange;
    } else {
      status = "High Waiting";
      statusColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Estimated Waiting Time",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔹 Gradient Card
            Container(
              padding: const EdgeInsets.all(27),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A11CB), Colors.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Header
                  Row(
                    children: const [
                      Icon(Icons.timer, color: Colors.white, size: 30),
                      SizedBox(width: 12),
                      Text(
                        "Smart Queue Status",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 🔹 Average Time
                  Text(
                    "Average Time per Student: $avgTimePerStudent min",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 🔹 Remaining Students
                  Text(
                    "Students Waiting: $remainingStudents",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 🔹 Total Time
                  Text(
                    "Total Estimated Wait: ~ $totalWaitTime minutes",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 🔹 Status Indicator
                  Row(
                    children: [
                      Icon(Icons.circle, color: statusColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Tips / Info Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Tips for Accurate Queue Management:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.deepPurple,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "• Keep the queue updated for accurate waiting time.\n"
                    "• Average time is auto-calculated from token intervals.\n"
                    "• Green = Low, Orange = Medium, Red = High wait time.\n"
                    "• Refresh dashboard regularly for real-time updates.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
