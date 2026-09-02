import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    // 🔹 If running on Web
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return "http://$host:8000/api";
    }

    // 🔹 If running on Android Emulator / Mobile
    try {
      if (Platform.isAndroid) {
        return "http://10.58.241.53:8000/api";
      }
    } catch (e) {
      // Platform check can fail on web if not careful, but kIsWeb handles it
    }

    // 🔹 Default for Desktop/iOS Simulator
    return "http://10.58.241.53:8000/api";
  }
}
