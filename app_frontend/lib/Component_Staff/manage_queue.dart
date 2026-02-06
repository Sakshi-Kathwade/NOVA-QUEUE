// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class ManageQueueScreen extends StatefulWidget {
  final String? adminId;

  const ManageQueueScreen({super.key, this.adminId});

  @override
  State<ManageQueueScreen> createState() => _ManageQueueScreenState();
}

class _ManageQueueScreenState extends State<ManageQueueScreen> {
  String? queueName;
  String? queueId;
  String queueStatus = "Active";

  String? currentTokenId;
  int currentTokenNumber = 0;
  String studentName = "N/A";
  String purpose = "N/A";

  int waitingCount = 0;
  int completedCount = 0;

  bool isLoading = true;
  bool isProcessing = false;
  String? errorMessage;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _fetchActiveQueue();
    if (queueName != null) {
      await _fetchCurrentToken();
      _startPolling();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "No active queue found";
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchCurrentToken();
    });
  }

  Future<void> _fetchActiveQueue() async {
    if (widget.adminId == null) return;

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/activequeue/${widget.adminId}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true && data["queueName"] != null) {
          setState(() {
            queueName = data["queueName"];
            queueId = data["data"]?["_id"];
            queueStatus = data["data"]?["status"] ?? "Active";
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrentToken() async {
    if (queueName == null) return;

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/currenttoken/$queueName"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (mounted) {
          setState(() {
            if (data["data"] != null) {
              currentTokenId = data["data"]["tokenId"];
              currentTokenNumber = data["data"]["tokenNumber"] ?? 0;
              studentName = data["data"]["studentName"] ?? "N/A";
              purpose = data["data"]["purpose"] ?? "N/A";
            } else {
              currentTokenId = null;
              currentTokenNumber = 0;
              studentName = "N/A";
              purpose = "N/A";
            }

            completedCount = data["data"]?["completedCount"] ?? 0;
            isLoading = false;
          });
        }

        await _fetchWaitingCount();
      }
    } catch (_) {}
  }

  Future<void> _fetchWaitingCount() async {
    if (queueName == null) return;

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/remainingtoken/$queueName"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            waitingCount = data["waitingCount"] ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleQueueStatus() async {
    if (queueId == null) return;

    setState(() => isProcessing = true);

    try {
      final newStatus = queueStatus == "Active" ? "Paused" : "Active";

      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/queuestatus/$queueId"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"status": newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() => queueStatus = newStatus);
      }
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _completeToken() async {
    if (currentTokenId == null || queueName == null) return;

    setState(() => isProcessing = true);

    try {
      await http.put(
        Uri.parse("${ApiConfig.baseUrl}/completetoken"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"queueName": queueName, "tokenId": currentTokenId}),
      );

      await _fetchCurrentToken();
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _nextToken() async {
    if (queueName == null || widget.adminId == null) return;

    setState(() => isProcessing = true);

    try {
      await http.put(
        Uri.parse("${ApiConfig.baseUrl}/nexttoken"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "queueName": queueName,
          "currentTokenId": currentTokenId,
          "adminId": widget.adminId,
        }),
      );

      await _fetchCurrentToken();
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _skipToken() async {
    if (currentTokenId == null || queueName == null) return;

    setState(() => isProcessing = true);

    try {
      await http.put(
        Uri.parse("${ApiConfig.baseUrl}/holdtoken"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"queueName": queueName, "tokenId": currentTokenId}),
      );

      await _nextToken();
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: const Color(0xff5E35B1),
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Queue",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(queueName ?? "No Queue", style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _toggleQueueStatus,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    queueStatus,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade100,
                      Colors.deepPurple.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// TOKEN
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xff5E35B1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.confirmation_number,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Current Token"),
                            Text(
                              currentTokenNumber > 0
                                  ? "A-$currentTokenNumber"
                                  : "N/A",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff5E35B1),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            queueStatus.toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// STUDENT CARD
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          _infoRow(Icons.person, "Student Name", studentName),
                          const Divider(),
                          _infoRow(Icons.description, "Purpose", purpose),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// STATS
                    Row(
                      children: [
                        _statCard(
                          Icons.people,
                          waitingCount,
                          "Waiting",
                          Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          Icons.check_circle,
                          completedCount,
                          "Completed",
                          Colors.green,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _actionBtn(Icons.skip_next, "Next", _nextToken),
                        _actionBtn(
                          Icons.check_circle,
                          "Complete",
                          _completeToken,
                        ),
                        _actionBtn(Icons.skip_previous, "Skip", _skipToken),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xff5E35B1)),
        const SizedBox(width: 8),
        Text(title),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _statCard(IconData icon, int count, String title, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(title, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey.shade700),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
