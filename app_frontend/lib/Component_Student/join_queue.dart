// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class JoinQueueScreen extends StatefulWidget {
  const JoinQueueScreen({super.key, required List<String> queues});

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
    "Computer Science",
    "Mechanical",
    "Civil",
    "Electronics",
  ];

  @override
  void initState() {
    super.initState();
    fetchQueues();
  }

  /// 🔹 FETCH QUEUE NAMES
  Future<void> fetchQueues() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/queue"),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          decoded["data"] != null &&
          decoded["data"] is List) {
        setState(() {
          queues = (decoded["data"] as List)
              .map((q) => q["queueName"].toString())
              .toList();
          isLoadingQueues = false;
        });
      } else {
        isLoadingQueues = false;
      }
    } catch (_) {
      isLoadingQueues = false;
    }
  }

  /// 🔹 SUBMIT TOKEN (POST API)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse("http://localhost:8000/api/token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "queueName": selectedQueue,
          "department": selectedDepartment,
          "purpose": purpose,
        }),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 201 && decoded["data"] != null) {
        final int tokenNumber = decoded["data"]["tokenNumber"];

        _showTokenDialog(tokenNumber);

        _formKey.currentState!.reset();
        setState(() {
          selectedQueue = null;
          selectedDepartment = null;
        });
      } else {
        _showError("Failed to generate token");
      }
    } catch (e) {
      _showError("Server not responding");
    }

    setState(() => isSubmitting = false);
  }

  /// 🎉 SUCCESS POPUP
  void _showTokenDialog(int tokenNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "🎫 Token Generated",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.confirmation_number,
              size: 60,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 12),
            const Text("Your Token Number", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              tokenNumber.toString(),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ),
        ],
      ),
    );
  }

  /// ❌ ERROR SNACKBAR
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text("Join Queue / Take Token"),
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
                            prefixIcon: Icon(Icons.edit_note),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          onChanged: (v) => purpose = v,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Take Token",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
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
