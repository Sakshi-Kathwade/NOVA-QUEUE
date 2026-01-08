import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StudentWaitingScreen extends StatefulWidget {
  final String studentId;
  final String queueName;

  const StudentWaitingScreen({
    super.key,
    required this.studentId,
    required this.queueName,
  });

  @override
  State<StudentWaitingScreen> createState() => _StudentWaitingScreenState();
}

class _StudentWaitingScreenState extends State<StudentWaitingScreen> {
  String queueName = "";
  int totalStudentsWaiting = 0;
  int currentTokenServing = 0;
  int averageWaitingTime = 0;
  bool isQueueOpen = true;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQueueData();
  }

  Future<void> fetchQueueData() async {
    final encodedQueue = Uri.encodeComponent(widget.queueName);
    final apiUrl =
        "http://localhost:8000/api/tokenget/$encodedQueue/${widget.studentId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          setState(() {
            queueName = data["queueName"];
            totalStudentsWaiting = data["studentsAhead"];
            averageWaitingTime = data["estimatedWaitingTime"];
            currentTokenServing = data["tokenNumber"];
            isQueueOpen = data["status"] == "waiting";
            isLoading = false;
          });
        } else {
          showError("No token found");
        }
      } else {
        showError("Failed to load queue data");
      }
    } catch (e) {
      showError("Server not reachable");
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

    // ✅ FIXED NaN ISSUE
    int total = currentTokenServing + totalStudentsWaiting;
    double progress = total > 0 ? currentTokenServing / total : 0.0;

    int estimatedTotalWait = totalStudentsWaiting * averageWaitingTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Queue Overview"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.queue, size: 40, color: Colors.deepPurple),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          queueName.isNotEmpty
                              ? queueName
                              : "Not Joined Any Queue",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: isQueueOpen ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isQueueOpen ? "Queue Open" : "Queue Closed",
                              style: TextStyle(
                                color: isQueueOpen ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.people,
                    title: "Students Ahead",
                    value: totalStudentsWaiting.toString(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    icon: Icons.timer,
                    title: "Avg. Waiting",
                    value: "$averageWaitingTime min",
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _infoCard(
              icon: Icons.play_circle_fill,
              title: "Your Token Number",
              value: currentTokenServing.toString(),
              color: Colors.deepPurple,
            ),

            const SizedBox(height: 24),

            const Text(
              "Queue Progress",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Card(
              elevation: 4,
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
                        const Text("Queue Completion"),
                        Text("${(progress * 100).toStringAsFixed(0)}%"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 14,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation(
                        Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Estimated waiting time: $estimatedTotalWait minutes",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
