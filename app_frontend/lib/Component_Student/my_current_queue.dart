// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateTokenScreen extends StatefulWidget {
  final String studentId;

  const CreateTokenScreen({super.key, required this.studentId});

  @override
  State<CreateTokenScreen> createState() => _CreateTokenScreenState();
}

class _CreateTokenScreenState extends State<CreateTokenScreen> {
  bool isLoading = false;

  final TextEditingController queueController = TextEditingController(
    text: "exam",
  );
  final TextEditingController purposeController = TextEditingController(
    text: "Exam related work",
  );
  final TextEditingController departmentController = TextEditingController(
    text: "Computer",
  );

  // 🔹 CREATE TOKEN API
  Future<void> createToken() async {
    setState(() => isLoading = true);

    final url = "http://localhost:8000/api/token";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "queueName": queueController.text.trim(),
          "department": departmentController.text.trim(),
          "purpose": purposeController.text.trim(),
          "studentId": widget.studentId,
        }),
      );

      final data = jsonDecode(response.body);

      // ✅ SUCCESS
      if (response.statusCode == 201 && data["success"] == true) {
        showPopup(
          message: "Token generated successfully 🎉",
          color: Colors.green,
          icon: Icons.check_circle,
        );
      }
      // ⚠️ ALREADY HAVE TOKEN (409)
      else if (response.statusCode == 409) {
        showPopup(
          message: data["message"] ?? "You already have a token",
          color: Colors.orange,
          icon: Icons.warning_amber_rounded,
        );
      }
      // ❌ OTHER ERROR
      else {
        showPopup(
          message: data["message"] ?? "Something went wrong",
          color: Colors.red,
          icon: Icons.error,
        );
      }
    } catch (e) {
      showPopup(
        message: "Server not reachable",
        color: Colors.red,
        icon: Icons.cloud_off,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🔹 BEAUTIFUL BOTTOM POPUP
  void showPopup({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate Token"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: queueController,
              decoration: const InputDecoration(labelText: "Queue Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: departmentController,
              decoration: const InputDecoration(labelText: "Department"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: purposeController,
              decoration: const InputDecoration(labelText: "Purpose"),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : createToken,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Generate Token",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
