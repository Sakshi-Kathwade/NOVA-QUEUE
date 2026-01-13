import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WaitingCardScreen extends StatefulWidget {
  const WaitingCardScreen({
    super.key,
    required int remainingStudents,
    required int avgTimePerStudent,
  });

  @override
  State<WaitingCardScreen> createState() => _WaitingCardScreenState();
}

class _WaitingCardScreenState extends State<WaitingCardScreen> {
  List students = [];
  bool isLoading = true;

  // 🔹 CHANGE QUEUE NAME HERE
  final String queueName = "ss";

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/getAlltoken/$queueName"),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        setState(() {
          students = decoded["data"];
          isLoading = false;
        });
      } else {
        isLoading = false;
        setState(() {});
      }
    } catch (e) {
      isLoading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Waiting Card"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // -------- WAITING CARD --------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    Icon(
                      Icons.confirmation_number,
                      size: 40,
                      color: Colors.deepPurple,
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Waiting Card",
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Waiting",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -------- STUDENTS WAITING LIST --------
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: const [
                      Text(
                        "Students Waiting",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
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
                                    "A${student["tokenNumber"]}",
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text("Student ${index + 1}"),
                                subtitle: Text(
                                  student["status"], // 🔹 BACKEND STATUS
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
          ),
        ],
      ),
    );
  }
}
