import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Component_Staff/theme_pref.dart';
import 'screen/home.dart';

// 🌙 Global Dark Mode notifier
ValueNotifier<bool> isDarkMode = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase (auto-initializes on Android via google-services.json)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase might already be initialized or auto-initialized on Android
    // Using debugPrint for development debugging
    debugPrint("Firebase initialization note: $e");
  }

  // 🔥 Load saved theme
  bool savedTheme = await ThemePref.load(); // make sure this returns bool
  isDarkMode.value = savedTheme;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'QueueNova',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      },
    );
  }
}
