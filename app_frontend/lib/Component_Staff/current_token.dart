import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CurrentTokenScreen extends StatefulWidget {
  final String queueName;

  const CurrentTokenScreen({super.key, required this.queueName});

  @override
  State<CurrentTokenScreen> createState() => _CurrentTokenScreenState();
}

class _CurrentTokenScreenState extends State<CurrentTokenScreen> {
  bool isLoading = true;
  String? error;

  int tokenNumber = 0;
  String studentName = "";
  String service = "";
  int completed = 0;
  int total = 0;

  @override
  void initState() {
    super.initState();
    fetchCurrentToken();
  }

  Future<void> fetchCurrentToken() async {
    try {
      final url = Uri.parse(
        "http://localhost:8000/api/currenttoken/${widget.queueName}",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        final data = jsonData['data'];

        if (data == null) {
          // No active token
          setState(() {
            error = "No active token";
            isLoading = false;
          });
        } else {
          setState(() {
            tokenNumber = data['tokenNumber'] ?? 0;
            studentName = data['studentName'] ?? "";
            service = data['purpose'] ?? "";
            completed = data['completedCount'] ?? 0;
            total = data['totalCount'] ?? 0;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = "No active token found";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Server error";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : completed / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Current Token"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// ---------- CURRENT TOKEN CARD ----------
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            "Now Serving",
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error != null ? "No Token" : "Token - $tokenNumber",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error != null
                                ? "No student in queue"
                                : "Student: $studentName",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            error != null ? "" : "Service: $service",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ---------- PROGRESS ----------
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Queue Progress",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade300,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$completed of $total completed",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  /// ---------- ACTION BUTTONS ----------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.pause),
                        label: const Text("Hold"),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(
                            245,
                            166,
                            48,
                            1,
                          ),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: error != null ? null : () {},
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text("Complete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            29,
                            187,
                            34,
                          ),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: error != null ? null : () {},
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.skip_next),
                        label: const Text("Next"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: error != null ? null : () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
