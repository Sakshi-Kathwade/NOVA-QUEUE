// ignore_for_file: deprecated_member_use, empty_catches

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QueueStatus extends StatefulWidget {
  const QueueStatus({super.key, required String studentId});

  @override
  State<QueueStatus> createState() => _QueueStatusState();
}

class _QueueStatusState extends State<QueueStatus> {
  bool isLoading = true;
  Map<String, dynamic>? queueData;
  String errorMsg = "";
  bool isActive = false;

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

  Future<void> updateQueueStatus(bool value) async {
    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/queuestatus/${queueData!["_id"]}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": value ? "Active" : "Inactive"}),
      );

      if (response.statusCode == 200) {
        setState(() => isActive = value);
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Queue Status"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg.isNotEmpty
          ? Center(child: Text(errorMsg))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // MAIN QUEUE CARD
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  queueData?["queueName"] ?? "Queue",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  isActive ? "ACTIVE" : "INACTIVE",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: isActive
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _detailRow(
                            Icons.access_time,
                            "Start Time",
                            queueData?["startTime"] ?? "--",
                          ),
                          _detailRow(
                            Icons.timer_off,
                            "End Time",
                            queueData?["endTime"] ?? "--",
                          ),
                          _detailRow(
                            Icons.people,
                            "Total Students",
                            "${queueData?["totalStudents"] ?? 0}",
                          ),

                          const Divider(height: 30),

                          Row(
                            children: [
                              const Text(
                                "Queue Status",
                                style: TextStyle(fontWeight: FontWeight.w600),
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

                  const SizedBox(height: 20),

                  const SizedBox(height: 24),

                  // INFO CARDS
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 10),
          Text("$label:", style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

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
