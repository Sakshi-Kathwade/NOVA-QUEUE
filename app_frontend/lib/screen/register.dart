// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'google_signin.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String selectedRole = "Student";
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;
  bool isGoogleLoading = false;

  // 🔥 POPUP
  void showPopup({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    bool success = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (success) {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  "OK",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      showPopup(
        title: "Password Mismatch",
        message: "Passwords do not match. Please enter the correct password.",
        icon: Icons.lock_outline,
        color: Colors.red,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/Register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text,
          "confirmPassword": confirmPasswordController.text,
          "role": selectedRole.toLowerCase(),
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 201) {
        showPopup(
          title: "Registration Successful 🎉",
          message:
              "Welcome to Smart Queue System!\nYour account has been created successfully.",
          icon: Icons.check_circle,
          color: Colors.deepPurple,
          success: true,
        );
      } else {
        final data = jsonDecode(response.body);
        showPopup(
          title: "Registration Failed",
          message: data["error"] ?? "Something went wrong",
          icon: Icons.error_outline,
          color: Colors.red,
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      showPopup(
        title: "Server Error",
        message: "Unable to connect to server.",
        icon: Icons.wifi_off,
        color: Colors.red,
      );
    }
  }

  // 🔐 GOOGLE SIGN-UP FUNCTION
  Future<void> registerWithGoogle() async {
    setState(() => isGoogleLoading = true);

    try {
      // 1️⃣ Sign in with Google using Firebase
      final AuthService authService = AuthService();
      final user = await authService.signInWithGoogle();

      if (user == null) {
        // User canceled the sign-in
        setState(() => isGoogleLoading = false);
        return;
      }

      // Validate user data
      if (user.email == null || user.email!.isEmpty) {
        setState(() => isGoogleLoading = false);
        showPopup(
          title: "Sign-Up Error",
          message:
              "Unable to get email from Google account.\nPlease ensure your Google account has an email address.",
          icon: Icons.error_outline,
          color: Colors.red,
        );
        return;
      }

      // 2️⃣ Register user with backend
      final response = await http
          .post(
            Uri.parse("${ApiConfig.baseUrl}/register/google"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": user.displayName ?? "User",
              "email": user.email!,
              "role": selectedRole.toLowerCase(),
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                "Request timeout. Please check your internet connection.",
              );
            },
          );

      setState(() => isGoogleLoading = false);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Check if user already exists
        if (data["alreadyExists"] == true) {
          showPopup(
            title: "Account Already Exists",
            message:
                "An account with this email already exists.\nPlease login instead.",
            icon: Icons.info_outline,
            color: Colors.orange,
            success: true,
          );
        } else {
          showPopup(
            title: "Registration Successful 🎉",
            message:
                "Welcome to Smart Queue System!\nYour account has been created successfully with Google.",
            icon: Icons.check_circle,
            color: Colors.deepPurple,
            success: true,
          );
        }
      } else {
        showPopup(
          title: "Registration Failed",
          message: data["error"] ?? "Something went wrong. Please try again.",
          icon: Icons.error_outline,
          color: Colors.red,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => isGoogleLoading = false);
      String errorMessage = "Google sign-in authentication failed.";

      switch (e.code) {
        case 'network-request-failed':
          errorMessage =
              "Network error. Please check your internet connection.";
          break;
        case 'sign_in_canceled':
          errorMessage = "Sign-in was canceled.";
          break;
        case 'account-exists-with-different-credential':
          errorMessage =
              "An account already exists with a different sign-in method.";
          break;
        default:
          errorMessage =
              "Authentication error: ${e.message ?? 'Unknown error'}";
      }

      showPopup(
        title: "Sign-In Error",
        message: errorMessage,
        icon: Icons.error_outline,
        color: Colors.red,
      );
    } catch (e) {
      setState(() => isGoogleLoading = false);
      String errorMessage = "Unable to complete Google sign-up.";

      final errorString = e.toString().toLowerCase();
      if (errorString.contains("network") ||
          errorString.contains("socket") ||
          errorString.contains("timeout") ||
          errorString.contains("connection")) {
        errorMessage =
            "Network error. Please check your internet connection and try again.";
      } else if (errorString.contains("sign_in_failed") ||
          errorString.contains("sign_in_canceled")) {
        errorMessage = "Google sign-in failed. Please try again.";
      } else if (errorString.contains("firebase")) {
        errorMessage =
            "Firebase error. Please ensure Firebase is properly configured.";
      } else {
        errorMessage = "An error occurred: ${e.toString()}";
      }

      showPopup(
        title: "Sign-Up Error",
        message: errorMessage,
        icon: Icons.error_outline,
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Register"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Fill details to get started",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Enter your name" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Enter email";
                        if (!RegExp(
                          r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                        ).hasMatch(v)) {
                          return "Enter valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: "Role",
                        prefixIcon: Icon(Icons.account_circle_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Student",
                          child: Text("Student"),
                        ),
                      ],
                      onChanged: (v) => setState(() => selectedRole = v!),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => hidePassword = !hidePassword),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.length < 6 ? "Minimum 6 characters" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: hideConfirmPassword,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hideConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => hideConfirmPassword = !hideConfirmPassword,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Confirm password" : null,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "REGISTER",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: (isLoading || isGoogleLoading)
                          ? null
                          : registerWithGoogle,
                      icon: isGoogleLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.deepPurple,
                              ),
                            )
                          : Image.network(
                              "https://img.icons8.com/color/48/google-logo.png",
                              height: 24,
                            ),
                      label: Text(
                        isGoogleLoading
                            ? "Signing up..."
                            : "Sign up with Google",
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: Colors.deepPurple),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
