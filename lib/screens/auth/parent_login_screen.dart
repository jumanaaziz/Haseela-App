import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_background.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'package:haseela_app/screens/parent/parent_profile_screen.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({Key? key}) : super(key: key);

  @override
  _ParentLoginScreenState createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // ✅ Attempt login with Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: identifier,
        password: password,
      );

      if (mounted) {
        _showSnackBar('Logged in successfully!', Colors.green);

        // 🚀 Navigate to parent profile screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParentProfileScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Too many attempts. Please wait a moment before trying again.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Check your connection.';
          break;
        default:
          errorMessage = 'Login failed. (${e.message})';
          break;
      }
      if (mounted) _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      if (mounted) _showSnackBar('Unexpected error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 14.sp)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AuthBackground(
        child: SafeArea(
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
                            Text(
                              'Welcome Back!',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 40.h),

                            // ✍ Email field
                            TextFormField(
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(fontSize: 16.sp),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.grey[500],
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.r),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 15.h,
                                ),
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: const Color(0xFF8D61B4),
                                  size: 20.sp,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                } else if (!value.contains('@')) {
                                  return 'Invalid email format';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20.h),

                            // 🔑 Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(fontSize: 16.sp),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.grey[500],
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.r),
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
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey[500],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 30.h),

                            // 🚪 Login button
                            SizedBox(
                              width: double.infinity,
                              height: 50.h,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8D61B4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.h,
                                        child: const CircularProgressIndicator(
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
                            SizedBox(height: 12.h),

                            // Forgot Password
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: const Color(0xFF8D61B4),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            SizedBox(height: 8.h),

                            // ➕ Sign up navigation
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.black54,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignUpScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Sign up',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF8D61B4),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 40.h),
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
      ),
    );
  }
}
