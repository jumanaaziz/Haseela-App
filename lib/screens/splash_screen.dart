import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth_background.dart';
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
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LaunchScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.transparent,  <-- حُذِف هذا السطر
      body: AuthBackground(
        child: SafeArea(
          child: Container(
            width: 1.sw, // يغطي عرض الشاشة بالكامل
            height: 1.sh, // يغطي ارتفاع الشاشة بالكامل
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 220.w,
                    height: 220.h,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 40.h),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF8D61B4),
                    ),
                    strokeWidth: 3.w,
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
