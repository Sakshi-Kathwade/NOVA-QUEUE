// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StudentWaiting extends StatefulWidget {
  final String studentId;
  final String queueName;

  const StudentWaiting({
    super.key,
    required this.studentId,
    required this.queueName,
  });

  @override
  State<StudentWaiting> createState() => _StudentWaitingState();
}

class _StudentWaitingState extends State<StudentWaiting> {
  String queueName = "";
  int totalStudentsWaiting = 0;
  int myTokenNumber = 0;
  int averageWaitingTime = 0;
  bool isQueueOpen = true;
  int? currentlyServingToken;
  List<Map<String, String>> liveQueueList = [];
  Timer? _pollTimer;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQueueData();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => fetchQueueData(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchQueueData() async {
    final encodedQueue = Uri.encodeComponent(widget.queueName);

    try {
      final tokenRes = await http.get(
        Uri.parse(
          "http://localhost:8000/api/tokenget/$encodedQueue/${widget.studentId}",
        ),
      );
      final currentRes = await http.get(
        Uri.parse("http://localhost:8000/api/currenttoken/$encodedQueue"),
      );
      final remainingRes = await http.get(
        Uri.parse("http://localhost:8000/api/remainingtoken/$encodedQueue"),
      );

      if (tokenRes.statusCode == 200) {
        final data = jsonDecode(tokenRes.body);
        if (data["success"] == true) {
          int? servingToken;
          if (currentRes.statusCode == 200) {
            final cur = jsonDecode(currentRes.body);
            if (cur["success"] == true && cur["data"] != null) {
              servingToken = cur["data"]["tokenNumber"];
            }
          }

          List<Map<String, String>> queueList = [];
          if (remainingRes.statusCode == 200) {
            final rem = jsonDecode(remainingRes.body);
            final waiting = (rem["waiting"] as List?) ?? [];
            for (var w in waiting) {
              queueList.add({
                "token": "A-${w["tokenNumber"] ?? w["token"] ?? "?"}",
                "name":
                    w["studentName"]?.toString() ??
                    w["name"]?.toString() ??
                    "—",
              });
            }
          }

          if (mounted) {
            setState(() {
              queueName = data["queueName"] ?? widget.queueName;
              totalStudentsWaiting = data["studentsAhead"] ?? 0;
              myTokenNumber = data["tokenNumber"] ?? 0;
              averageWaitingTime = data["estimatedWaitingTime"] ?? 5;
              isQueueOpen = (data["status"] ?? "waiting") == "waiting";
              currentlyServingToken = servingToken;
              liveQueueList = queueList;
              isLoading = false;
            });
          }
        } else if (!isLoading) {
          showError("No token found");
        }
      } else if (!isLoading) {
        showError("Failed to load queue data");
      }
    } catch (e) {
      if (!isLoading && mounted) showError("Server not reachable");
    }
  }

  void showError(String message) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    int estimatedTotalWait = totalStudentsWaiting * averageWaitingTime;
    int serving = currentlyServingToken ?? 0;
    double progress = (myTokenNumber > 0 && serving > 0)
        ? (serving >= myTokenNumber ? 1.0 : serving / myTokenNumber)
        : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Live Queue"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Queue name & status
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.queue,
                      size: 40,
                      color: Colors.deepPurple.shade700,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            queueName.isNotEmpty ? queueName : widget.queueName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isQueueOpen
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isQueueOpen
                                                  ? Colors.green
                                                  : Colors.red)
                                              .withOpacity(0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isQueueOpen ? "Queue Open" : "Queue Closed",
                                style: TextStyle(
                                  color: isQueueOpen
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Live status message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    color: Colors.orange.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "You are waiting in line",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Currently serving & Your token
            Row(
              children: [
                Expanded(
                  child: _highlightCard(
                    title: "Currently Serving",
                    value: currentlyServingToken?.toString() ?? "—",
                    color: Colors.green,
                    icon: Icons.play_circle_filled,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _highlightCard(
                    title: "Your Token",
                    value: myTokenNumber.toString(),
                    color: Colors.deepPurple,
                    icon: Icons.confirmation_number,
                    isMine: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.people,
                    title: "Position Ahead",
                    value: totalStudentsWaiting.toString(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    icon: Icons.timer,
                    title: "Est. Wait",
                    value: "$estimatedTotalWait min",
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              "Queue Progress",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Progress",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation(
                        Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Estimated waiting time: $estimatedTotalWait minutes",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (liveQueueList.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                "Queue Tokens",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 10),
              ...liveQueueList.asMap().entries.map((e) {
                final tokenStr = e.value["token"] ?? "—";
                final isMine = tokenStr == "A-$myTokenNumber";
                final isServing =
                    currentlyServingToken != null &&
                    tokenStr == "A-$currentlyServingToken";
                Color bg = Colors.grey.shade100;
                if (isServing) bg = Colors.green.shade100;
                if (isMine) bg = Colors.deepPurple.shade50;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMine
                          ? Colors.deepPurple
                          : (isServing ? Colors.green : Colors.grey.shade300),
                      width: isMine || isServing ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isServing
                            ? Icons.play_circle_filled
                            : (isMine ? Icons.person : Icons.schedule),
                        color: isServing
                            ? Colors.green
                            : (isMine ? Colors.deepPurple : Colors.grey),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        tokenStr,
                        style: TextStyle(
                          fontWeight: isMine || isServing
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "You",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                      if (isServing) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Serving",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _highlightCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    bool isMine = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
