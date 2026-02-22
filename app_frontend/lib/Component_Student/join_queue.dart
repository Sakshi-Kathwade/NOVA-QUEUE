// ignore_for_file: use_build_context_synchronously, deprecated_member_use
// obscureText: true,
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';

class JoinQueueScreen extends StatefulWidget {
  final String studentId; // ✅ Auto-filled from login (userId from backend)

  const JoinQueueScreen({super.key, required this.studentId});

  @override
  State<JoinQueueScreen> createState() => _JoinQueueScreenState();
}

class _JoinQueueScreenState extends State<JoinQueueScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedQueue;
  String? selectedDepartment;
  String purpose = "";

  bool isSubmitting = false;
  bool isLoadingQueues = true;

  List<String> queues = [];

  final List<String> departments = [
    "Computer Technology",
    "Mechanical",
    "Civil",
    "Electronics",
    "Electrical",
    "Artificial Intelligence",
  ];

  late TextEditingController studentIdController;

  @override
  void initState() {
    super.initState();
    // ✅ Auto-fill studentId from login
    studentIdController = TextEditingController(text: widget.studentId);
    fetchQueues();
  }

  @override
  void dispose() {
    studentIdController.dispose();
    super.dispose();
  }

  // 🔹 FETCH QUEUES
  Future<void> fetchQueues() async {
    try {
      final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/queue"));
      final decoded = jsonDecode(res.body);

      if (res.statusCode == 200 && decoded["data"] != null) {
        setState(() {
          queues = (decoded["data"] as List)
              .map((q) => q["queueName"].toString())
              .toList();
          isLoadingQueues = false;
        });
      } else {
        setState(() => isLoadingQueues = false);
      }
    } catch (e) {
      setState(() => isLoadingQueues = false);
    }
  }

  // 🔹 SUBMIT TOKEN
  Future<void> submitToken() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "queueName": selectedQueue,
          "department": selectedDepartment,
          "purpose": purpose,
          "studentId": widget.studentId, // ✅ Use login userId
        }),
      );

      final decoded = jsonDecode(response.body);

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          decoded["success"] == true &&
          decoded["data"] != null) {
        final int tokenNumber = decoded["data"]["tokenNumber"];
        showTokenDialog(tokenNumber);

        _formKey.currentState!.reset();
        setState(() {
          selectedQueue = null;
          selectedDepartment = null;
          purpose = "";
        });
      } else {
        showError(decoded["message"] ?? "Failed to generate token");
      }
    } catch (e) {
      showError("Server not responding");
    }

    setState(() => isSubmitting = false);
  }

  // 🔹 SUCCESS POPUP
  void showTokenDialog(int tokenNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(child: Text("🎫 Token Generated")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.confirmation_number,
              size: 60,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            Text(
              tokenNumber.toString(),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 ERROR SNACKBAR
  void showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Queue"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoadingQueues
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // ✅ Auto-filled Student ID (read-only)
                        TextFormField(
                          controller: studentIdController,
                          readOnly: true,
                          // obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Student ID",
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedQueue,
                          items: queues
                              .map(
                                (q) =>
                                    DropdownMenuItem(value: q, child: Text(q)),
                              )
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: "Queue Name *",
                            prefixIcon: Icon(Icons.queue),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null ? "Select queue" : null,
                          onChanged: (v) => setState(() => selectedQueue = v),
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedDepartment,
                          items: departments
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: "Department",
                            prefixIcon: Icon(Icons.apartment),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) =>
                              setState(() => selectedDepartment = v),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: "Purpose *",
                            prefixIcon: Icon(Icons.edit),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          onChanged: (v) => purpose = v,
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : submitToken,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                            ),
                            child: isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Take Token",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
