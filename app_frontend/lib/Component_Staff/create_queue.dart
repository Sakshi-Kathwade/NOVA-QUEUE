// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class CreateQueueScreen extends StatefulWidget {
  final String? adminId;
  const CreateQueueScreen({super.key, this.adminId});

  @override
  State<CreateQueueScreen> createState() => _CreateQueueScreenState();
}

class _CreateQueueScreenState extends State<CreateQueueScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController queueName = TextEditingController();
  final TextEditingController maxStudents = TextEditingController();

  String department = "Admission";
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  bool isLoading = false;

  // 🔹 Convert TimeOfDay → DateTime
  DateTime _convertToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  // 🔹 CREATE QUEUE API
  Future<void> createQueueApi() async {
    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select start & end time")));
      return;
    }
    if (widget.adminId == null || widget.adminId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Admin not found. Please login again.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/createqueue"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "adminId": widget.adminId,
          "queueName": queueName.text.trim(),
          "department": department,
          "maxStudents": int.parse(maxStudents.text),
          "startTime": _convertToDateTime(startTime!).toIso8601String(),
          "endTime": _convertToDateTime(endTime!).toIso8601String(),
        }),
      );

      final respBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final message = respBody is Map && respBody["message"] != null
          ? respBody["message"].toString()
          : null;

      if (response.statusCode == 201) {
        _showSuccessDialog(message ?? "Queue Created Successfully");

        _formKey.currentState!.reset();
        queueName.clear();
        maxStudents.clear();
        startTime = null;
        endTime = null;
        setState(() {});
      } else {
        _showErrorDialog(message ?? "Failed to create queue");
      }
    } catch (e) {
      _showErrorDialog("Server Error");
    }

    setState(() => isLoading = false);
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text("Success", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("OK", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
     showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text("Error", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Create Queue",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Queue Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Queue Name
                  TextFormField(
                    controller: queueName,
                    decoration: _inputDecoration(
                      label: "Queue Name",
                      icon: Icons.queue,
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Department
                  DropdownButtonFormField(
                    value: department,
                    decoration: _inputDecoration(
                      label: "Department",
                      icon: Icons.apartment,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Admission",
                        child: Text("Admission"),
                      ),
                      DropdownMenuItem(value: "Exam", child: Text("Exam")),
                      DropdownMenuItem(value: "Fee", child: Text("Fee")),
                    ],
                    onChanged: (v) => department = v!,
                  ),
                  const SizedBox(height: 16),

                  // Max Students
                  TextFormField(
                    controller: maxStudents,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      label: "Max Students",
                      icon: Icons.people,
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 20),

                  // Time Pickers
                  Row(
                    children: [
                      Expanded(
                        child: _timeButton(
                          label: "Start Time",
                          time: startTime,
                          onTap: () async {
                            startTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timeButton(
                          label: "End Time",
                          time: endTime,
                          onTap: () async {
                            endTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                createQueueApi();
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Create Queue",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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

  // 🔹 INPUT DECORATION
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  // 🔹 TIME BUTTON
  Widget _timeButton({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.grey),
        ),
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            time == null ? "Select Time" : time.format(context),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
