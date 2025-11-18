import 'dart:async';
import 'package:flutter/material.dart';
import 'package:locally/common/routes/app_routes.dart';

class GifSplash extends StatefulWidget {
  const GifSplash({super.key});

  @override
  GifSplashState createState() => GifSplashState();
}

class GifSplashState extends State<GifSplash> {
  @override
  void initState() {
    super.initState();
    // ... in your GifSplashState initState method
    Timer(const Duration(seconds: 0), () {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.appGate, // <-- CHANGED (Was WelcomeScreen)
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // same as native splash
      body: Image.asset(
        'assets/splash/final.gif', // your GIF
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,

        // --------------------------
      ),
    );
  }
}
