import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_background.dart';
import 'package:haseela_app/screens/parent/parent_profile_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  bool _usernameHasMinLength = false;
  bool _usernameHasNoSpaces = false;
  bool _usernameHasOnlyAllowedChars = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordRequirements);
    _usernameController.addListener(_checkUsernameRequirements);
  }

  void _checkPasswordRequirements() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasSpecialChar = RegExp(r'[!@#\$%\^&\*]').hasMatch(password);
    });
  }

  void _checkUsernameRequirements() {
    final username = _usernameController.text;
    setState(() {
      _usernameHasMinLength = username.length >= 4; // or 6, your choice
      _usernameHasNoSpaces = !username.contains(' ');
      _usernameHasOnlyAllowedChars = RegExp(
        r'^[a-zA-Z0-9._]+$',
      ).hasMatch(username);
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Create Firebase Auth user
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final uid = credential.user!.uid;

      // 2️⃣ Create parent document in Firestore
      await FirebaseFirestore.instance.collection('Parents').doc(uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': '05${_phoneController.text.trim()}',
        'avatar': null,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'parent',
      });

      // 3️⃣ Navigate to parent profile screen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParentProfileScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Sign up failed';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 20.h,
                  ),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 500.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 180.w,
                            height: 180.h,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'Create Parent Account',
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20.h),

                          // 📄 Form Section
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        'First Name',
                                        _firstNameController,
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Enter first name';
                                          }
                                          if (!RegExp(
                                            r'^[a-zA-Z\s]+$',
                                          ).hasMatch(val)) {
                                            return 'First name must contain only letters';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: _buildTextField(
                                        'Last Name',
                                        _lastNameController,
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Enter last name';
                                          }
                                          if (!RegExp(
                                            r'^[a-zA-Z\s]+$',
                                          ).hasMatch(val)) {
                                            return 'Last name must contain only letters';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15.h),
                                _buildTextField(
                                  'Username',
                                  _usernameController,
                                  validator: (val) =>
                                      val!.isEmpty ? 'Enter username' : null,
                                ),
                                SizedBox(height: 8.h),
                                if (_usernameController.text.isNotEmpty)
                                  _buildUsernameRequirements(),

                                SizedBox(height: 15.h),
                                _buildTextField(
                                  'Email',
                                  _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Enter email address';
                                    }
                                    if (!RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                    ).hasMatch(val)) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 15.h),
                                _buildPhoneField(),
                                SizedBox(height: 15.h),
                                _buildPasswordField(),
                                SizedBox(height: 8.h),

                                if (_passwordController.text.isNotEmpty)
                                  _buildPasswordRequirements(),
                                SizedBox(height: 15.h),
                                _buildTextField(
                                  'Confirm Password',
                                  _confirmPasswordController,
                                  isPassword: true,
                                  validator: (val) => val!.isEmpty
                                      ? 'Confirm your password'
                                      : null,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 30.h),
                          SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8D61B4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.r),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          SizedBox(height: 20.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  minimumSize: Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: const Color(
                                    0xFF8D61B4,
                                  ).withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.r),
                                  ),
                                ),
                                child: Text(
                                  'Log in',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF8D61B4),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF8D61B4),
                                    decorationThickness: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.number,
      maxLength: 8,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Enter phone number';
        }
        if (val.length != 8) {
          return 'Phone must be exactly 8 digits';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: 'Phone Number',
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.r),
          borderSide: BorderSide.none,
        ),
        prefixText: '05 ',
        prefixStyle: TextStyle(
          fontSize: 16.sp,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        counterText: '',
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      validator: (val) => val!.length < 8 ? 'Min 8 characters' : null,
      decoration: InputDecoration(
        hintText: 'Password',
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.r),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
            size: 20.sp,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          _buildRequirementItem('At least 8 characters', _hasMinLength),
          _buildRequirementItem('One uppercase letter (A-Z)', _hasUppercase),
          _buildRequirementItem('One lowercase letter (a-z)', _hasLowercase),
          _buildRequirementItem('One number (0-9)', _hasNumber),
          _buildRequirementItem(
            'One special character (!@#\$%^&*)',
            _hasSpecialChar,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16.sp,
          color: isValid ? Colors.green : Colors.grey,
        ),
        SizedBox(width: 8.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: isValid ? Colors.green : Colors.grey[600],
            fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameRequirements() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Username Requirements:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          _buildRequirementItem('At least 4 characters', _usernameHasMinLength),
          _buildRequirementItem('No spaces', _usernameHasNoSpaces),
          _buildRequirementItem(
            'Only letters, numbers, . or _',
            _usernameHasOnlyAllowedChars,
          ),
        ],
      ),
    );
  }
}
