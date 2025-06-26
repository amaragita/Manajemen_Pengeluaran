import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_navigation.dart';
import 'utils/preferences_helper.dart';
import 'utils/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Manajemen Pengeluaran',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            home: FutureBuilder<String?>(
              future: PreferencesHelper.getUsername(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return snapshot.hasData ? const MainNavigation() : const LoginScreen();
              },
            ),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/dashboard': (context) => const MainNavigation(initialIndex: 0),
              '/chart': (context) => const MainNavigation(initialIndex: 1),
              '/expense': (context) => const MainNavigation(initialIndex: 2),
              '/account': (context) => const MainNavigation(initialIndex: 3),
              '/settings': (context) => const MainNavigation(initialIndex: 4),
            },
          );
        },
      ),
    );
  }
}
