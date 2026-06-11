import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uum_net/pages/loginpage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Wait 3 seconds then go to Login
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The Container stretches to fill the screen and holds the gradient
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade800, // Darker purple at the top
              Colors.deepPurple.shade400, // Lighter purple at the bottom
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // White icon instead of purple
              Icon(
                Icons.wifi_tethering,
                size: 100,
                color: Colors.white, 
              ),
              SizedBox(height: 20),
              // White text with a slight letter spacing for a modern feel
              Text(
                "UUM Network Monitor",
                style: TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 40),
              // White loading indicator to match the theme
              CircularProgressIndicator(
                color: Colors.white, 
              )
            ],
          ),
        ),
      ),
    );
  }
}