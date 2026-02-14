
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _verificationId;
  int _step = 1; // 1: Phone, 2: OTP, 3: Password
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Send OTP
  Future<void> _sendOtp() async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showResultDialog("Please enter phone number", false);
      return;
    }
    // Simple validation (must ensure country code if using Firebase)
    if (!phone.startsWith('+')) {
       _showResultDialog("Please enter phone number with Country Code (e.g. +91...)", false);
       return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
           // Auto-retrieval on Android
           await _auth.signInWithCredential(credential);
           setState(() {
             _step = 3;
             _isLoading = false;
           });
           _showResultDialog("Phone Verified Automatically!", true);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showResultDialog(e.message ?? "Verification Failed", false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _step = 2;
            _isLoading = false;
          });
          _showResultDialog("OTP Sent Successfully", true);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showResultDialog("Error: $e", false);
    }
  }

  // 2. Verify OTP
  Future<void> _verifyOtp() async {
    String smsCode = _otpController.text.trim();
    if (smsCode.isEmpty) {
      _showResultDialog("Enter OTP", false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      // Sign in to verify ownership
      await _auth.signInWithCredential(credential);
      
      setState(() {
        _step = 3;
        _isLoading = false;
      });
      _showResultDialog("Phone Verified!", true);

    } catch (e) {
      setState(() => _isLoading = false);
      _showResultDialog("Invalid OTP", false);
    }
  }

  // 3. Reset Password
  Future<void> _resetPassword() async {
    String password = _passwordController.text;
    String confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      _showResultDialog("Password must be at least 6 characters", false);
      return;
    }
    if (password != confirm) {
      _showResultDialog("Passwords do not match", false);
      return;
    }

    setState(() => _isLoading = true);

    try {
       final response = await http.post(
         Uri.parse("${ApiConfig.baseUrl}/reset-password"),
         headers: {"Content-Type": "application/json"},
         body: jsonEncode({
           "phoneNumber": _phoneController.text.trim(),
           "newPassword": password
         })
       );

       final data = jsonDecode(response.body);
       
       if (response.statusCode == 200 && data['success'] == true) {
         _showResultDialog("Password Reset Successfully!", true);
         await Future.delayed(const Duration(seconds: 2));
         if (mounted) Navigator.pop(context); // Go back to login
       } else {
         _showResultDialog(data['message'] ?? "Failed to reset password", false);
       }

    } catch (e) {
      _showResultDialog("Server Error: $e", false);
    }
    setState(() => _isLoading = false);
  }

  void _showResultDialog(String message, bool isSuccess) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error, 
                color: isSuccess ? Colors.green : Colors.red, 
                size: 60
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess ? "Success" : "Error", 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.deepPurple : Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            Text(
              _step == 1 ? "Enter Phone Number" : _step == 2 ? "Verify OTP" : "Reset Password",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _step == 1 
                 ? "We will send an OTP to your phone number to reset your password." 
                 : _step == 2 
                    ? "Enter the OTP sent to ${_phoneController.text}"
                    : "Create a new strong password.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            if (_step == 1) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number (+91...)",
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Send OTP", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ]
            else if (_step == 2) ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Enter OTP",
                  prefixIcon: const Icon(Icons.sms),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Verify OTP", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                 onPressed: () => setState(() => _step = 1),
                 child: const Text("Change Phone Number"),
              )
            ]
            else if (_step == 3) ...[
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Reset Password", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
