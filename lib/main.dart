import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SuperiorApp());
}

class SuperiorApp extends StatelessWidget {
  const SuperiorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Superior AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C3AED),
          secondary: Color(0xFF5B21B6),
          surface: Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0D0D),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
