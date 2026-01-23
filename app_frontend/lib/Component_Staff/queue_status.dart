// ignore_for_file: deprecated_member_use, empty_catches

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class QueueStatus extends StatefulWidget {
  final String? adminId;
  const QueueStatus({super.key, this.adminId, required String studentId});

  @override
  State<QueueStatus> createState() => _QueueStatusState();
}

class _QueueStatusState extends State<QueueStatus> {
  bool isLoading = true;
  Map<String, dynamic>? queueData;
  String errorMsg = "";
  bool isActive = false;
  Timer? _dateTimer; // ✅ Timer for real-time date update
  Timer? _dataTimer; // ✅ Timer for real-time data updates
  
  // ✅ Real-time data
  int waitingCount = 0;
  String currentToken = "--";
  int completedToday = 0;
  int pendingToday = 0;

  @override
  void initState() {
    super.initState();
    fetchQueueStatus();
    // ✅ Start timer to update date every minute
    _dateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {}); // Refresh to update date
    });
    // ✅ Start timer to update data every 3 seconds
    _dataTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (queueData != null && queueData!["queueName"] != null) {
        fetchQueueData();
      }
    });
  }

  @override
  void dispose() {
    _dateTimer?.cancel();
    _dataTimer?.cancel();
    super.dispose();
  }

  // ✅ Fetch active queue status
  Future<void> fetchQueueStatus() async {
    try {
      // ✅ Fetch active queue instead of all queues
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/activequeue/${widget.adminId ?? ''}"),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true && data["data"] != null) {
        setState(() {
          queueData = data["data"];
          isActive = queueData!["status"] == "Active";
          isLoading = false;
        });
        // ✅ Fetch queue data after queue is loaded
        if (queueData!["queueName"] != null) {
          fetchQueueData();
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

  // ✅ Fetch real-time queue data (waiting count, current token, completed count)
  Future<void> fetchQueueData() async {
    if (queueData == null || queueData!["queueName"] == null) return;

    final queueName = queueData!["queueName"] as String;

    try {
      // Fetch waiting students count
      final waitingResponse = await http.get(
        Uri.parse("http://localhost:8000/api/remainingtoken/$queueName"),
      );

      if (waitingResponse.statusCode == 200) {
        final waitingData = json.decode(waitingResponse.body);
        final waitingList = (waitingData["waiting"] as List?) ?? [];
        setState(() {
          waitingCount = waitingList.length;
        });
      }

      // Fetch current token and completed count
      final tokenResponse = await http.get(
        Uri.parse("http://localhost:8000/api/currenttoken/$queueName"),
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = json.decode(tokenResponse.body);
        if (tokenData["data"] != null) {
          final tokenNumber = tokenData["data"]["tokenNumber"] ?? 0;
          final completedCount = tokenData["data"]["completedCount"] ?? 0;
          final totalCount = tokenData["data"]["totalCount"] ?? 0;
          setState(() {
            currentToken = tokenNumber > 0 ? "A-$tokenNumber" : "--";
            completedToday = completedCount;
            pendingToday = totalCount - completedCount;
          });
        } else {
          setState(() {
            currentToken = "--";
            completedToday = 0;
            pendingToday = 0;
          });
        }
      }
    } catch (e) {
      // Silent fail - will retry on next poll
    }
  }

  // ✅ Format time from ISO string to readable format
  String _formatTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return "--";
    try {
      final dateTime = DateTime.parse(isoTime);
      return DateFormat('hh:mm a').format(dateTime); // Format: 09:30 AM
    } catch (e) {
      return isoTime; // Return as is if parsing fails
    }
  }

  // ✅ Get today's date in readable format
  String _getTodayDate() {
    return DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());
    // Format: Monday, January 15, 2024
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
        // ✅ Refresh queue status after update
        fetchQueueStatus();
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Queue Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _getTodayDate(), // ✅ Real-time date display
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
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
                            _formatTime(queueData?["startTime"]),
                          ),
                          _detailRow(
                            Icons.timer_off,
                            "End Time",
                            _formatTime(queueData?["endTime"]),
                          ),
                          _detailRow(
                            Icons.people,
                            "Total Students",
                            "${queueData?["maxStudents"] ?? queueData?["totalStudents"] ?? 0}",
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
                    children: [
                      InfoCard(
                        title: "Students Waiting",
                        value: waitingCount.toString(),
                        icon: Icons.people,
                        color: Colors.orange,
                      ),
                      InfoCard(
                        title: "Current Token",
                        value: currentToken,
                        icon: Icons.confirmation_number,
                        color: Colors.blue,
                      ),
                      InfoCard(
                        title: "Completed Today",
                        value: completedToday.toString(),
                        icon: Icons.check_circle,
                        color: Colors.purple,
                      ),
                      InfoCard(
                        title: "Pending Today",
                        value: pendingToday.toString(),
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
