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
  bool hasActiveToken = false;

  int tokenNumber = 0;
  String queueName = "";
  int studentsAhead = 0;
  int estimatedWaitMinutes = 0;
  String status = "";
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    queueName = widget.queueName;
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
      if (mounted) {
        fetchQueueData(isBackgroundPoll: true);
      }
    });
  }

  // 🔹 FETCH QUEUE DATA
  Future<void> fetchQueueData({bool isBackgroundPoll = false}) async {
    final effectiveQueue =
        widget.queueName.isNotEmpty ? Uri.encodeComponent(widget.queueName) : "all";

    final apiUrl =
        "${ApiConfig.baseUrl}/tokenget/$effectiveQueue/${widget.studentId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          if (mounted) {
            setState(() {
              tokenNumber = data["tokenNumber"] ?? 0;
              queueName = data["queueName"] ?? widget.queueName;
              studentsAhead = data["studentsAhead"] ?? 0;
              estimatedWaitMinutes = data["estimatedWaitingTime"] ?? 0;
              status = data["status"] ?? "waiting";
              hasActiveToken = true;
              isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              hasActiveToken = false;
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            hasActiveToken = false;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!isBackgroundPoll && mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 🔹 DELETE TOKEN API
  Future<void> cancelTokenApi() async {
    final targetQueue = queueName.isNotEmpty ? queueName : widget.queueName;
    final encodedQueue = Uri.encodeComponent(targetQueue);

    final deleteUrl =
        "${ApiConfig.baseUrl}/tokendelete/$encodedQueue/$tokenNumber";

    try {
      final response = await http.delete(Uri.parse(deleteUrl));
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded["success"] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Token cancelled successfully"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        showError("Failed to cancel token");
      }
    } catch (e) {
      showError("Server not responding");
    }
  }

  void showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 🔹 CONFIRM CANCEL
  void confirmCancel() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Cancel Token"),
          ],
        ),
        content: const Text(
          "Are you sure you want to cancel your token? You will lose your position in queue.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No, Keep"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : !hasActiveToken
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 72,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No Active Token",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "You do not currently have any active token in queue.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text("Refresh Status"),
                          onPressed: () {
                            setState(() => isLoading = true);
                            fetchQueueData();
                          },
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 🔹 TOKEN CARD
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.confirmation_number,
                                size: 48,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "A-$tokenNumber",
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Your Token Number",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _infoTile(
                        icon: Icons.queue,
                        label: "Queue Name",
                        value: queueName.isNotEmpty ? queueName : "Smart Queue",
                      ),
                      _infoTile(
                        icon: Icons.people,
                        label: "Students Ahead",
                        value: "$studentsAhead students",
                      ),
                      _infoTile(
                        icon: Icons.timer,
                        label: "Estimated Waiting Time",
                        value: "$estimatedWaitMinutes minutes",
                      ),
                      _infoTile(
                        icon: Icons.info_outline,
                        label: "Status",
                        value: status.toUpperCase(),
                        valueColor: status.toLowerCase() == "waiting"
                            ? Colors.orange.shade700
                            : status.toLowerCase() == "serving"
                                ? Colors.green.shade700
                                : Colors.deepPurple,
                      ),

                      const SizedBox(height: 16),

                      // 🔔 NOTIFICATION SWITCH
                      Card(
                        elevation: 2,
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
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.cancel),
                          label: const Text(
                            "Cancel Token",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    Color valueColor = Colors.black87,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        trailing: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
            color: valueColor,
          ),
        ),
      ),
    );
  }
}
