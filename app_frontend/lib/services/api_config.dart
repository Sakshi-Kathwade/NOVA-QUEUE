import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    // 🔹 If running on Web
    if (kIsWeb) {
      return "http://10.155.83.53:8000/api";
    }

    // 🔹 If running on Android Emulator
    try {
      if (Platform.isAndroid) {
        return "http://10.155.83.53:8000/api";
      }
    } catch (e) {
      // Platform check can fail on web if not careful, but kIsWeb handles it
    }

    // 🔹 Default for Desktop/iOS Simulator
    return "http://10.155.83.53:8000/api";
  }
}
