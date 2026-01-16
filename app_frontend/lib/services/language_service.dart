import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'user_language_';
  static const String defaultLanguage = 'english';

  // ✅ Get language for specific user (admin or student)
  static Future<String> getLanguage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_languageKey$userId') ?? defaultLanguage;
    } catch (e) {
      return defaultLanguage;
    }
  }

  // ✅ Set language for specific user
  static Future<void> setLanguage(String userId, String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_languageKey$userId', language);
    } catch (e) {
      // Silent fail
    }
  }

  // ✅ Clear language preference (on logout)
  static Future<void> clearLanguage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_languageKey$userId');
    } catch (e) {
      // Silent fail
    }
  }
}
