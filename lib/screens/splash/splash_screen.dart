import 'package:flutter/material.dart';
import '../auth_background.dart';
import 'launch_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to launch screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LaunchScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use MediaQuery safely instead of ScreenUtil here
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: SizedBox(
            width: size.width, // ✅ replaces 1.sw
            height: size.height, // ✅ replaces 1.sh
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Use MediaQuery size or fixed values safely
                  Image.asset(
                    'assets/images/logo.png',
                    width: size.width * 0.55,
                    height: size.width * 0.55,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF8D61B4),
                    ),
                    strokeWidth: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
