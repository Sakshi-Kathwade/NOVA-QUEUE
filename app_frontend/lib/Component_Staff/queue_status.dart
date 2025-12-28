// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QueueStatusScreen extends StatefulWidget {
  const QueueStatusScreen({super.key});

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  bool isLoading = true;
  Map<String, dynamic>? queueData;
  String errorMsg = "";
  bool isActive = false;

  @override
  void initState() {
    super.initState();
    fetchQueueStatus();
  }

  // 🔹 FETCH QUEUE
  Future<void> fetchQueueStatus() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/queue"),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["data"].isNotEmpty) {
        setState(() {
          queueData = data["data"][0];
          isActive = queueData!["status"] == "Active";
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

  // 🔹 UPDATE STATUS
  Future<void> updateQueueStatus(bool value) async {
    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/queuestatus/${queueData!["_id"]}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": value ? "Active" : "Inactive"}),
      );

      if (response.statusCode == 200) {
        setState(() => isActive = value);

        _showCenterPopup(
          value ? "Queue Activated" : "Queue Deactivated",
          value ? Icons.check_circle : Icons.cancel,
          value ? Colors.green : Colors.red,
        );
      }
    } catch (e) {
      _showCenterPopup("Failed to update queue", Icons.error, Colors.red);
    }
  }

  // 🔹 CENTER POPUP
  void _showCenterPopup(String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text("OK"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text("Queue Status"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg.isNotEmpty
          ? Center(child: Text(errorMsg))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ✅ PROFESSIONAL QUEUE + STATUS CARD
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Queue Name + Status Badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  queueData?["queueName"] ?? "Queue Name",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isActive ? "ACTIVE" : "INACTIVE",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 🔹 Time & Students
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _infoItem(
                                Icons.access_time,
                                "Start",
                                queueData?["startTime"] ?? "--",
                              ),
                              _infoItem(
                                Icons.timer_off,
                                "End",
                                queueData?["endTime"] ?? "--",
                              ),
                              _infoItem(
                                Icons.people,
                                "Students",
                                "${queueData?["totalStudents"] ?? 0}",
                              ),
                            ],
                          ),

                          const Divider(height: 30),

                          // 🔹 Toggle Status
                          Row(
                            children: [
                              Icon(
                                isActive ? Icons.lock_open : Icons.lock_outline,
                                color: isActive ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isActive
                                    ? "Queue is Active"
                                    : "Queue is Inactive",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: isActive,
                                onChanged: updateQueueStatus,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🔹 GRID INFO (UNCHANGED)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: const [
                      InfoCard(
                        title: "Students Waiting",
                        value: "0",
                        icon: Icons.people,
                        color: Colors.orange,
                      ),
                      InfoCard(
                        title: "Current Token",
                        value: "--",
                        icon: Icons.confirmation_number,
                        color: Colors.blue,
                      ),
                      InfoCard(
                        title: "Completed Today",
                        value: "0",
                        icon: Icons.check_circle,
                        color: Colors.purple,
                      ),
                      InfoCard(
                        title: "Pending Today",
                        value: "0",
                        icon: Icons.pending_actions,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // 🔹 Small Info Item Widget
  Widget _infoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

// 🔹 INFO CARD
class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const InfoCard({
    super.key,
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
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
