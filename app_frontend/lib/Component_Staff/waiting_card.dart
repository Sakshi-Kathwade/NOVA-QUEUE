import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WaitingCardScreen extends StatefulWidget {
  const WaitingCardScreen({super.key, required this.queueName});

  final String queueName;

  @override
  State<WaitingCardScreen> createState() => _WaitingCardScreenState();
}

class _WaitingCardScreenState extends State<WaitingCardScreen> {
  List students = [];
  bool isLoading = true;
  Timer? _pollTimer; // ✅ Timer for real-time updates

  // ✅ ANDROID EMULATOR SAFE URL
  final String baseUrl = "http://localhost:8000";

  @override
  void initState() {
    super.initState();
    fetchStudents();
    startPolling(); // ✅ Start real-time polling
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel(); // ✅ Clean up timer
    super.dispose();
  }
  
  // ✅ REAL-TIME: Start polling for updates every 3 seconds
  void startPolling() {
    _pollTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      fetchStudents();
    });
  }

  Future<void> fetchStudents() async {
    if (widget.queueName.isEmpty) {
      if (mounted) {
        setState(() {
          students = [];
          isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/remainingtoken/${widget.queueName}"),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        setState(() {
          students = decoded["waiting"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          students = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        students = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Student Waiting "),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // 🔹 TOP SUMMARY CARD (NEW & CLEAN UI)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Queue Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Queue Name",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.queueName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),

                    // Waiting Count
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Students Waiting",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          students.length.toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔹 WAITING LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.queueName.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 48, color: Colors.orange),
                            const SizedBox(height: 16),
                            const Text(
                              "Queue is not active or not generated.",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : students.isEmpty
                        ? const Center(child: Text("No students waiting"))
                        : ListView.builder(
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              final student = students[index];

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepPurple.shade100,
                                    child: Text(
                                      "A-${student["tokenNumber"]}",
                                      style: const TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: const Text("Waiting"),
                                  subtitle: Text(
                                    student["purpose"] ?? "Purpose not available",
                                  ),
                                  trailing: const Icon(
                                    Icons.hourglass_bottom,
                                    color: Colors.orange,
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
