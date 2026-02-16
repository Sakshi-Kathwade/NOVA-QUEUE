import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEmailVerified = false;
  bool _isLoading = false;
  String? _studentId;
  String? _studentName;

  // 1. Verify Email
  Future<void> _verifyEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack("Please enter your email", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _isEmailVerified = true;
          _studentId = data['studentId'];
          _studentName = data['name'];
        });
        _showSnack("Email verified successfully", Colors.green);
      } else {
        _showSnack(data['message'] ?? "Email not found", Colors.red);
      }
    } catch (e) {
      _showSnack("Server Error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Reset Password
  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty || confirm.isEmpty) {
      _showSnack("Please fill all password fields", Colors.red);
      return;
    }
    if (password != confirm) {
      _showSnack("Passwords do not match", Colors.red);
      return;
    }
    if (password.length < 6) {
      _showSnack("Password must be at least 6 characters", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "newPassword": password
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showSuccessDialog();
      } else {
        _showSnack(data['message'] ?? "Failed to update password", Colors.red);
      }
    } catch (e) {
      _showSnack("Server Error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Success"),
          ],
        ),
        content: const Text(
          "Password updated successfully!\nYou can now login with your new password.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Go back to login
            },
            child: const Text("Go to Login", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            
            // EMAIL VERIFICATION STEP
            if (!_isEmailVerified) ...[
               const Text(
                "Enter your registered email to find your account.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Verify Email", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ]
            
            // RESET PASSWORD STEP
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.shade200)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Account Found:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text("Student ID: $_studentId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      ],
                    ),
                    if (_studentName != null) ...[
                      const SizedBox(height: 4),
                       Row(
                        children: [
                          const Icon(Icons.badge, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text("Name: $_studentName", style: const TextStyle(fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text("Create a New Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "New Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Update Password", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
