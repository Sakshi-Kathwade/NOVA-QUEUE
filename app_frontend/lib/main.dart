// import 'package:flutter/material.dart';
// import 'screen/home.dart';

// void main() async {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Smart Queue Management System',
//       home: const HomeScreen(),
//     );
//   }
// }
import 'package:flutter/material.dart';
// import 'Component_Staff/admin_setting.dart';
import 'Component_Staff/theme_pref.dart';
import 'screen/home.dart';

// 🌙 Global Dark Mode notifier
ValueNotifier<bool> isDarkMode = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Load saved theme
  isDarkMode.value = await ThemePref.load();
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
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      },
    );
  }
}
