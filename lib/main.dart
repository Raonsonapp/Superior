import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
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
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10A37F),
          surface: Color(0xFF1A1A1A),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
