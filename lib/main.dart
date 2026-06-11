import 'dart:io'; // Required for HttpOverrides to fix the SSL bug
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uum_net/pages/splashpage.dart';

// --- THIS CLASS FIXES THE ANDROID SSL BUG --- 
class LetEncryptOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- ACTIVATE THE OVERRIDE HERE ---
  HttpOverrides.global = LetEncryptOverride();
  
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UUM Network',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Enable modern Material 3 design
        useMaterial3: true,
        
        // Generate a unified color palette based on your deep purple brand color
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        
        // Set a global background color so screens aren't stark white
        scaffoldBackgroundColor: Colors.grey.shade50,
        
        // Global styling for all ElevatedButtons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        
        // Global styling for all TextFields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
          prefixIconColor: Colors.deepPurple,
        ),
        
        // Global AppBar styling
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const SplashPage(),
    );
  }
}