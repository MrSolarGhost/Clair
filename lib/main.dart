import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/input_service.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const ClairApp());
}

class ClairApp extends StatelessWidget {
  const ClairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InputService()),
      ],
      child: MaterialApp(
        title: 'Clair',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Console-like dark theme
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: Colors.blue.shade300,
            secondary: Colors.purple.shade300,
            surface: const Color(0xFF1A1A1A),
          ),
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          cardTheme: const CardThemeData(
            color: Color(0xFF1A1A1A),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
