import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://10.0.2.2:8000";

  // ================= LOGIN API =================
  static Future<bool> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================= REGISTER API =================
  static Future<bool> registerUser(
    String name,
    String email,
    String password,
    String confirmPassword,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "confirmPassword": confirmPassword, // IMPORTANT
          "role": role,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
