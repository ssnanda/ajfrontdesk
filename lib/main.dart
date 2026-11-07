import 'package:flutter/material.dart';
import 'app_config.dart';
import 'home_screen.dart';
import 'setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const ReceptionApp());
}

class ReceptionApp extends StatelessWidget {
  const ReceptionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AJ Front Desk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: AppConfig.configured ? const HomeScreen() : const SetupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
