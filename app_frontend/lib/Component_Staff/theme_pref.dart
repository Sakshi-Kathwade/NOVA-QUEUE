import 'package:shared_preferences/shared_preferences.dart';

class ThemePref {
  static const String _key = 'darkMode';

  static Future<void> save(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  static Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false; // default light
  }
}
