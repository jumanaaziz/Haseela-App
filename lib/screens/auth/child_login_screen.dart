import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haseela_app/screens/child/child_home_screen.dart';
import '../auth_background.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

String hashPinWithSalt(String pin, String salt) {
  final bytes = utf8.encode(pin + salt);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({Key? key}) : super(key: key);

  @override
  _ChildLoginScreenState createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parentUsernameController = TextEditingController();
  final _childUsernameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;

  @override
  void dispose() {
    _parentUsernameController.dispose();
    _childUsernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final parentUsername = _parentUsernameController.text.trim();
    final childUsername = _childUsernameController.text.trim();
    final pin = _pinController.text.trim();

    try {
      // 1️⃣ Find parent by username
      final parentSnap = await FirebaseFirestore.instance
          .collection('Parents')
          .where('username', isEqualTo: parentUsername)
          .limit(1)
          .get();

      if (parentSnap.docs.isEmpty) {
        _showSnackBar('Parent username not found', Colors.red);
        return;
      }

      final parentDoc = parentSnap.docs.first;
      final parentId = parentDoc.id;

      // 2️⃣ Find child by username under this parent
      final childSnap = await FirebaseFirestore.instance
          .collection('Parents')
          .doc(parentId)
          .collection('Children')
          .where('username', isEqualTo: childUsername)
          .limit(1)
          .get();

      if (childSnap.docs.isEmpty) {
        _showSnackBar('Child username not found', Colors.red);
        return;
      }

      final childDoc = childSnap.docs.first;
      final childId = childDoc.id;
      final childData = childDoc.data();

      // 3️⃣ Retrieve the email stored for this child
      final email = childData['email'];
      if (email == null) {
        _showSnackBar('No email found for this child account', Colors.red);
        return;
      }

      // 4️⃣ Sign in to Firebase Auth with email & PIN
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pin,
        );
      } on FirebaseAuthException catch (e) {
        _showSnackBar('Incorrect PIN or email: ${e.message}', Colors.red);
        return;
      }

      // ✅ SUCCESS: Navigate to child home screen
      _showSnackBar('Login successful!', Colors.green);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(parentId: parentId, childId: childId),
        ),
      );
    } catch (e) {
      _showSnackBar('Login failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Validation methods
  String? _validateParentUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Parent username is required';
    }
    if (value.trim().length < 3) {
      return 'Parent username must be at least 3 characters';
    }
    return null;
  }

  String? _validateChildUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Your username is required';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validatePin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PIN is required';
    }
    if (value.trim().length != 6) {
      return 'PIN must be exactly 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'PIN must contain only numbers';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(25.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 20.h,
                        ),
                        child: Center(
                          child: Container(
                            constraints: BoxConstraints(maxWidth: 500.w),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Welcome text
                                  Text(
                                    'Welcome Back!',
                                    style: TextStyle(
                                      fontSize: 28.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Enter your login details',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 40.h),

                                  // Parent Username field
                                  TextFormField(
                                    controller: _parentUsernameController,
                                    style: TextStyle(fontSize: 16.sp),
                                    decoration: InputDecoration(
                                      hintText: 'Parent\'s Username',
                                      hintStyle: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.grey[500],
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          25.r,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 15.h,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.person_outline,
                                        color: const Color(0xFF8D61B4),
                                        size: 20.sp,
                                      ),
                                    ),
                                    validator: _validateParentUsername,
                                  ),
                                  SizedBox(height: 20.h),

                                  // Child Username field
                                  TextFormField(
                                    controller: _childUsernameController,
                                    style: TextStyle(fontSize: 16.sp),
                                    decoration: InputDecoration(
                                      hintText: 'Your Username',
                                      hintStyle: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.grey[500],
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          25.r,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 15.h,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.alternate_email,
                                        color: const Color(0xFF8D61B4),
                                        size: 20.sp,
                                      ),
                                    ),
                                    validator: _validateChildUsername,
                                  ),
                                  SizedBox(height: 20.h),

                                  // 6-digit PIN field
                                  TextFormField(
                                    controller: _pinController,
                                    obscureText: _obscurePin,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    style: TextStyle(fontSize: 16.sp),
                                    decoration: InputDecoration(
                                      hintText: '6-digit PIN',
                                      hintStyle: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.grey[500],
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          25.r,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 15.h,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock,
                                        color: const Color(0xFF8D61B4),
                                        size: 20.sp,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePin
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: const Color(0xFF8D61B4),
                                          size: 20.sp,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePin = !_obscurePin;
                                          });
                                        },
                                      ),
                                      counterText: '', // Hide character counter
                                    ),
                                    validator: _validatePin,
                                  ),
                                  SizedBox(height: 30.h),

                                  // Login button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50.h,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF8D61B4,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            25.r,
                                          ),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              width: 20.w,
                                              height: 20.h,
                                              child:
                                                  const CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                            )
                                          : Text(
                                              'Log In',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: 20.h),

                                  // Help text
                                  Text(
                                    'Contact your parent if you forgot your login details',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
