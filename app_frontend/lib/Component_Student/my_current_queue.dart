// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';

class MyCurrentQueueScreen extends StatefulWidget {
  final String queueName;
  final String studentId; // ✅ REQUIRED

  const MyCurrentQueueScreen({
    super.key,
    required this.queueName,
    required this.studentId,
  });

  @override
  State<MyCurrentQueueScreen> createState() => _MyCurrentQueueScreenState();
}

class _MyCurrentQueueScreenState extends State<MyCurrentQueueScreen> {
  bool notificationEnabled = true;
  bool isLoading = true;

  int tokenNumber = 0;
  String queueName = "";
  int studentsAhead = 0;
  int estimatedWaitMinutes = 0;
  String status = "";
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    fetchQueueData();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      fetchQueueData();
    });
  }

  // 🔹 FETCH QUEUE DATA
  Future<void> fetchQueueData() async {
    final encodedQueue = Uri.encodeComponent(widget.queueName);

    final apiUrl =
        "${ApiConfig.baseUrl}/tokenget/$encodedQueue/${widget.studentId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          setState(() {
            tokenNumber = data["tokenNumber"];
            queueName = data["queueName"];
            studentsAhead = data["studentsAhead"];
            estimatedWaitMinutes = data["estimatedWaitingTime"];
            status = data["status"];
            isLoading = false;
          });
        } else {
          // If token not found anymore (e.g. was finished), go back
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        showError("Failed to load data");
      }
    } catch (e) {
      showError("Server not reachable");
    }
  }

  // 🔹 DELETE TOKEN API
  Future<void> cancelTokenApi() async {
    final encodedQueue = Uri.encodeComponent(widget.queueName);

    final deleteUrl =
        "${ApiConfig.baseUrl}/tokendelete/$encodedQueue/$tokenNumber";

    try {
      final response = await http.delete(Uri.parse(deleteUrl));
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token cancelled successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        showError("Failed to cancel token");
      }
    } catch (e) {
      showError("Server not responding");
    }
  }

  void showError(String message) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // 🔹 CONFIRM CANCEL
  void confirmCancel() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Token"),
        content: const Text("Are you sure you want to cancel your token?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              cancelTokenApi();
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
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text("My Current Queue"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            tokenNumber.toString(),
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

                  _infoTile(
                    icon: Icons.queue,
                    label: "Queue Name",
                    value: queueName,
                  ),
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
                    valueColor: status == "waiting"
                        ? Colors.orange
                        : Colors.green,
                  ),

                  const SizedBox(height: 24),

                  // 🔔 NOTIFICATION SWITCH
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
                      value: notificationEnabled,
                      onChanged: (v) {
                        setState(() => notificationEnabled = v);
                      },
                      secondary: const Icon(
                        Icons.notifications_active,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ❌ CANCEL TOKEN BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.cancel),
                      label: const Text("Cancel Token"),
                      onPressed: confirmCancel,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.black,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
        ),
      ),
    );
  }
}
