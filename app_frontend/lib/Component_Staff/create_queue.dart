import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateQueueScreen extends StatefulWidget {
  const CreateQueueScreen({super.key});

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

  // 🔹 API CALL
  Future<void> createQueueApi() async {
    if (startTime == null || endTime == null) {
      _showError("Please select start and end time");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://localhost:8000/api/createqueue"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "queueName": queueName.text.trim(),
          "department": department,
          "maxStudents": int.parse(maxStudents.text),
          "startTime": startTime!.format(context),
          "endTime": endTime!.format(context),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _showSuccessPopup();
        _formKey.currentState!.reset();
        queueName.clear();
        maxStudents.clear();
        startTime = null;
        endTime = null;
        setState(() {});
      } else {
        _showError(data["message"] ?? "Failed to create queue");
      }
    } catch (e) {
      _showError("Server not reachable");
    }

    setState(() => isLoading = false);
  }

  // 🔹 SUCCESS POPUP
  void _showSuccessPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Queue Created Successfully 🎉",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // 🔹 ERROR SNACKBAR
  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Create Queue"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Queue Name
                  TextFormField(
                    controller: queueName,
                    decoration: const InputDecoration(
                      labelText: "Queue Name",
                      prefixIcon: Icon(Icons.queue),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter queue name" : null,
                  ),
                  const SizedBox(height: 16),

                  // Department
                  DropdownButtonFormField(
                    initialValue: department,
                    decoration: const InputDecoration(
                      labelText: "Department",
                      prefixIcon: Icon(Icons.apartment),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Admission",
                        child: Text("Admission"),
                      ),
                      DropdownMenuItem(value: "Exam", child: Text("Exam")),
                      DropdownMenuItem(value: "Fee", child: Text("Fee")),
                    ],
                    onChanged: (value) => setState(() => department = value!),
                  ),
                  const SizedBox(height: 16),

                  // Max Students
                  TextFormField(
                    controller: maxStudents,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Max Students",
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter max students" : null,
                  ),
                  const SizedBox(height: 16),

                  // Time Pickers
                  Row(
                    children: [
                      Expanded(
                        child: _timePicker(
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
                        child: _timePicker(
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
                  const SizedBox(height: 24),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(isLoading ? "Creating..." : "Create Queue"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                createQueueApi();
                              }
                            },
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

  // 🔹 TIME PICKER WIDGET
  Widget _timePicker({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(time == null ? "Select" : time.format(context)),
      ),
    );
  }
}
