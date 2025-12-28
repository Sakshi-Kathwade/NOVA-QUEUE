// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';

class JoinQueueScreen extends StatefulWidget {
  const JoinQueueScreen({super.key});

  @override
  State<JoinQueueScreen> createState() => _JoinQueueScreenState();
}

class _JoinQueueScreenState extends State<JoinQueueScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedQueue;
  String? selectedDepartment;
  String purpose = "";
  TimeOfDay? arrivalTime;

  bool isSubmitting = false;

  final List<String> queues = [
    "Admission Queue",
    "Fee Payment Queue",
    "Document Verification",
    "Counseling Queue",
  ];

  final List<String> departments = [
    "Computer Science",
    "Mechanical",
    "Civil",
    "Electronics",
  ];

  void _pickArrivalTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => arrivalTime = picked);
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    await Future.delayed(const Duration(seconds: 2)); // simulate API call

    setState(() => isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🎫 Token successfully generated!"),
        backgroundColor: Colors.green,
      ),
    );

    _formKey.currentState!.reset();
    setState(() {
      selectedQueue = null;
      selectedDepartment = null;
      arrivalTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text("Join Queue / Take Token"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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

                  // 🔹 QUEUE NAME
                  DropdownButtonFormField<String>(
                    value: selectedQueue,
                    items: queues
                        .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: "Queue Name *",
                      prefixIcon: Icon(Icons.queue),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null ? "Please select a queue" : null,
                    onChanged: (value) => setState(() => selectedQueue = value),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 DEPARTMENT (OPTIONAL)
                  DropdownButtonFormField<String>(
                    value: selectedDepartment,
                    items: departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: "Department (Optional)",
                      prefixIcon: Icon(Icons.apartment),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        setState(() => selectedDepartment = value),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 PURPOSE
                  TextFormField(
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Purpose / Reason *",
                      prefixIcon: Icon(Icons.edit_note),
                      border: OutlineInputBorder(),
                      helperText: "Briefly explain your reason for visit",
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? "Purpose is required"
                        : null,
                    onChanged: (value) => purpose = value,
                  ),

                  const SizedBox(height: 16),

                  // 🔹 ARRIVAL TIME
                  InkWell(
                    onTap: _pickArrivalTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Estimated Arrival Time (Optional)",
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        arrivalTime == null
                            ? "Select time"
                            : arrivalTime!.format(context),
                        style: TextStyle(
                          color: arrivalTime == null
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🔹 SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.confirmation_number),
                      label: Text(
                        isSubmitting ? "Processing..." : "Take Token",
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting ? null : _submitForm,
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
