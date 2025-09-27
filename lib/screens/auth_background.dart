import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3F7FF), Color(0xFFEAF2FF), Color(0xFFE6ECFF)],
        ),
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(
            top: -60.h,
            left: -40.w,
            child: _bubble(140.w, Color(0xFFB28DDB).withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: -50.h,
            right: -30.w,
            child: _bubble(180.w, Color(0xFF8D61B4).withValues(alpha: 0.16)),
          ),
          Positioned(
            top: 120.h,
            right: -20.w,
            child: _bubble(90.w, Color(0xFF6E72C3).withValues(alpha: 0.14)),
          ),
          Positioned(
            bottom: 120.h,
            left: -10.w,
            child: _bubble(80.w, Color(0xFF198CCA).withValues(alpha: 0.12)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 6,
          ),
        ],
      ),
    );
  }
}
