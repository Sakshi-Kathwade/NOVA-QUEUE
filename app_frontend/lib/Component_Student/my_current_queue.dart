// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class MyCurrentQueueScreen extends StatefulWidget {
  const MyCurrentQueueScreen({super.key});

  @override
  State<MyCurrentQueueScreen> createState() => _MyCurrentQueueScreenState();
}

class _MyCurrentQueueScreenState extends State<MyCurrentQueueScreen> {
  bool notificationEnabled = true;

  // 🔹 SAMPLE DATA (Later connect with backend API)
  final String tokenNumber = "A-12";
  final String queueName = "Admission Queue";
  final int studentsAhead = 6;
  final int estimatedWaitMinutes = 30;
  final String status = "Waiting"; // Waiting / In Progress

  void _cancelToken() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Token"),
        content: const Text(
          "Are you sure you want to cancel your token?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Token cancelled successfully"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // 🔹 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text("My Current Queue"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 TOKEN CARD
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.confirmation_number,
                      size: 50,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tokenNumber,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Your Token Number",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 QUEUE DETAILS
            _infoTile(icon: Icons.queue, label: "Queue Name", value: queueName),
            _infoTile(
              icon: Icons.people,
              label: "Students Ahead",
              value: studentsAhead.toString(),
            ),
            _infoTile(
              icon: Icons.timer,
              label: "Estimated Waiting Time",
              value: "$estimatedWaitMinutes minutes",
            ),
            _infoTile(
              icon: Icons.info_outline,
              label: "Status",
              value: status,
              valueColor: status == "Waiting" ? Colors.orange : Colors.green,
            ),

            const SizedBox(height: 24),

            // 🔹 NOTIFICATION TOGGLE
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                activeColor: Colors.deepPurple,
                title: const Text(
                  "Receive Notifications",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text("Get notified when your turn is near"),
                value: notificationEnabled,
                onChanged: (value) {
                  setState(() {
                    notificationEnabled = value;
                  });
                },
                secondary: const Icon(
                  Icons.notifications_active,
                  color: Colors.deepPurple,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 CANCEL TOKEN BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.cancel),
                label: const Text(
                  "Cancel Token",
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: _cancelToken,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 REUSABLE INFO TILE
  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.black,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
        ),
      ),
    );
  }
}
