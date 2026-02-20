import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kisanbazaar/firebase_options.dart';
import 'package:kisanbazaar/screens/splash/splash_screen.dart';
import 'package:kisanbazaar/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kisan Bazaar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // You can change to ThemeMode.system for auto dark mode
      home: SplashScreen(),
    );
  }
}
