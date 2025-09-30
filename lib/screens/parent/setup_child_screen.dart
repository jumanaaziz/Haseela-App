import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crypto/crypto.dart';
import 'package:toastification/toastification.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SetupChildScreen extends StatefulWidget {
  final String parentId;
  final String parentUsername;

  const SetupChildScreen({
    super.key,
    required this.parentId,
    required this.parentUsername,
  });

  @override
  State<SetupChildScreen> createState() => _SetupChildScreenState();
}

class _SetupChildScreenState extends State<SetupChildScreen> {
  final TextEditingController _childUsernameController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;

  bool _childUsernameHasMinLength = false;
  bool _childUsernameHasNoSpaces = false;
  bool _childUsernameHasOnlyAllowedChars = false;
  bool _isChildUsernameAvailable = true; // optional uniqueness check

  @override
  void initState() {
    super.initState();
    _childUsernameController.addListener(_checkChildUsernameRequirements);
  }

  void _checkChildUsernameRequirements() async {
    final username = _childUsernameController.text.trim();

    setState(() {
      _childUsernameHasMinLength = username.length >= 3;
      _childUsernameHasNoSpaces = !username.contains(' ');
      _childUsernameHasOnlyAllowedChars = RegExp(
        r'^[a-zA-Z0-9._]+$',
      ).hasMatch(username);
    });

    // ✅ Optional: Check if username is already taken in Firestore
    if (_childUsernameHasMinLength &&
        _childUsernameHasNoSpaces &&
        _childUsernameHasOnlyAllowedChars) {
      final doc = await FirebaseFirestore.instance
          .collection(
            'ChildrenUsernames',
          ) // 🔸 use a separate collection for children
          .doc(username)
          .get();

      setState(() {
        _isChildUsernameAvailable = !doc.exists;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _showToast(String message, ToastificationType type) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.fillColored,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  Future<String?> _createChildAuthAccount(String email, String pin) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pin);

      return userCredential.user?.uid; // ✅ Return Firebase UID
    } on FirebaseAuthException catch (e) {
      print('Error creating child Firebase Auth account: $e');
      _showToast(
        'Failed to create child account: ${e.message}',
        ToastificationType.error,
      );
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firstName = _firstNameController.text.trim();
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final pin = _pinController.text.trim();

      // 1️⃣ Generate salt + hash
      String _generateSalt([int length = 16]) {
        final rand = Random.secure();
        final values = List<int>.generate(length, (i) => rand.nextInt(256));
        return base64Url.encode(values);
      }

      String _hashPin(String pin, String salt) {
        final bytes = utf8.encode('$pin:$salt');
        return sha256.convert(bytes).toString();
      }

      final salt = _generateSalt();
      final pinHash = _hashPin(pin, salt);

      // 2️⃣ Create Firebase Auth account for the child
      final childUid = await _createChildAuthAccount(email, pin);
      if (childUid == null) {
        setState(() => _isLoading = false);
        return; // stop if failed
      }

      // 3️⃣ Check if username already exists for this parent
      final childDocRef = FirebaseFirestore.instance
          .collection('Parents')
          .doc(widget.parentId)
          .collection('Children')
          .doc(childUid); // 👈 using UID now, not username

      final existingDoc = await childDocRef.get();
      if (existingDoc.exists) {
        _showToast('Child account already exists.', ToastificationType.error);
        setState(() => _isLoading = false);
        return;
      }

      // 4️⃣ Save child metadata to Firestore
      final childData = {
        'firstName': firstName,
        'username': username,
        'username_lc': username.toLowerCase(),
        'email': email,
        'pin_hash': pinHash,
        'pin_salt': salt,
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
        'role': 'child',
      };

      // 4️⃣ Save child metadata to Firestore
      await childDocRef.set(childData);

      // 5️⃣ Initialize required subcollections for the child
      await _initializeChildSubcollections(childUid);

      _showToast(
        '✅ Child account created successfully 🎉',
        ToastificationType.success,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showToast('Error: $e', ToastificationType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeChildSubcollections(String childUid) async {
    final parentRef = FirebaseFirestore.instance
        .collection('Parents')
        .doc(widget.parentId);
    final childRef = parentRef.collection('Children').doc(childUid);

    final batch = FirebaseFirestore.instance.batch();

    // 1️⃣ Tasks — create an example placeholder (or leave empty if preferred)
    final taskRef = childRef.collection('Tasks').doc(); // auto ID
    batch.set(taskRef, {
      'allowance': 0,
      'assignedBy': parentRef,
      'completedImagePath': '',
      'createdAt': FieldValue.serverTimestamp(),
      'dueDate': null,
      'priority': 'normal',
      'status': 'new',
      'taskName': 'Example Task',
    });

    // 2️⃣ Transaction — example placeholder
    final transactionRef = childRef.collection('Transaction').doc();
    batch.set(transactionRef, {
      'amount': 0,
      'category': 'General',
      'date': FieldValue.serverTimestamp(),
      'description': '',
      'fromWallet': 'spending',
      'id': transactionRef.id,
      'toWallet': 'saving',
      'type': 'deposit',
      'userID': childUid,
    });

    // 3️⃣ Wallet — initialize starting balances
    final walletRef = childRef.collection('Wallet').doc();
    batch.set(walletRef, {
      'createdAt': FieldValue.serverTimestamp(),
      'id': walletRef.id,
      'savingBalance': 0,
      'spendingBalance': 0,
      'totalBalance': 0,
      'updatedAt': FieldValue.serverTimestamp(),
      'userId': childUid,
    });

    // 4️⃣ Wishlist — example placeholder
    final wishlistRef = childRef.collection('Wishlist').doc();
    batch.set(wishlistRef, {
      'createdAt': FieldValue.serverTimestamp(),
      'itemName': 'Example Item',
      'itemPrice': 0,
      'progress': 0,
      'statuss': 'pending', // 👈 matches your original field name exactly
    });

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final isSmallScreen = screenHeight < 600;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isTablet, isDesktop, isSmallScreen, isWideScreen),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop
                      ? 48.w
                      : isTablet
                      ? 32.w
                      : 16.w,
                  vertical: isSmallScreen ? 12.h : 20.h,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop
                        ? 600.w
                        : isTablet
                        ? 500.w
                        : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(
                        isTablet,
                        isDesktop,
                        isSmallScreen,
                        isWideScreen,
                      ),
                      SizedBox(
                        height: isDesktop
                            ? 40.h
                            : isTablet
                            ? 32.h
                            : isSmallScreen
                            ? 24.h
                            : 32.h,
                      ),
                      _buildForm(
                        isTablet,
                        isDesktop,
                        isSmallScreen,
                        isWideScreen,
                      ),
                      SizedBox(
                        height: isDesktop
                            ? 40.h
                            : isTablet
                            ? 32.h
                            : isSmallScreen
                            ? 24.h
                            : 32.h,
                      ),
                      _buildSubmitButton(
                        isTablet,
                        isDesktop,
                        isSmallScreen,
                        isWideScreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    bool isTablet,
    bool isDesktop,
    bool isSmallScreen,
    bool isWideScreen,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop
            ? 24.w
            : isTablet
            ? 20.w
            : 16.w,
        vertical: isDesktop
            ? 20.h
            : isTablet
            ? 16.h
            : isSmallScreen
            ? 12.h
            : 16.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(
                isDesktop
                    ? 12.w
                    : isTablet
                    ? 10.w
                    : isSmallScreen
                    ? 8.w
                    : 10.w,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(
                  isDesktop
                      ? 12.r
                      : isTablet
                      ? 10.r
                      : isSmallScreen
                      ? 8.r
                      : 10.r,
                ),
              ),
              child: Icon(
                Icons.close,
                color: Colors.grey[600],
                size: isDesktop
                    ? 24.sp
                    : isTablet
                    ? 22.sp
                    : isSmallScreen
                    ? 18.sp
                    : 20.sp,
              ),
            ),
          ),
          SizedBox(
            width: isDesktop
                ? 16.w
                : isTablet
                ? 14.w
                : isSmallScreen
                ? 12.w
                : 14.w,
          ),
          Expanded(
            child: Text(
              'Set up Child Account',
              style: TextStyle(
                fontSize: isDesktop
                    ? 24.sp
                    : isTablet
                    ? 22.sp
                    : isSmallScreen
                    ? 18.sp
                    : 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(
    bool isTablet,
    bool isDesktop,
    bool isSmallScreen,
    bool isWideScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(
            isDesktop
                ? 20.w
                : isTablet
                ? 18.w
                : isSmallScreen
                ? 14.w
                : 16.w,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              isDesktop
                  ? 20.r
                  : isTablet
                  ? 18.r
                  : isSmallScreen
                  ? 14.r
                  : 16.r,
            ),
          ),
          child: Icon(
            Icons.person_add,
            color: const Color(0xFF8B5CF6),
            size: isDesktop
                ? 48.sp
                : isTablet
                ? 44.sp
                : isSmallScreen
                ? 32.sp
                : 40.sp,
          ),
        ),
        SizedBox(
          height: isDesktop
              ? 24.h
              : isTablet
              ? 20.h
              : isSmallScreen
              ? 16.h
              : 20.h,
        ),
        Text(
          'Create Child Profile',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop
                ? 32.sp
                : isTablet
                ? 28.sp
                : isSmallScreen
                ? 24.sp
                : 28.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        SizedBox(
          height: isDesktop
              ? 12.h
              : isTablet
              ? 10.h
              : isSmallScreen
              ? 8.h
              : 10.h,
        ),
        Text(
          'Enter your child\'s information to create their account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop
                ? 18.sp
                : isTablet
                ? 16.sp
                : isSmallScreen
                ? 14.sp
                : 16.sp,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(
    bool isTablet,
    bool isDesktop,
    bool isSmallScreen,
    bool isWideScreen,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildFormField(
            _firstNameController,
            'First Name',
            'Enter child\'s first name',
            Icons.person_outline,
            isTablet,
            isDesktop,
            isSmallScreen,
            isWideScreen,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'First name is required' : null,
          ),
          SizedBox(height: 20.h),
          _buildFormField(
            _usernameController,
            'Username',
            'Choose a unique username',
            Icons.alternate_email,
            isTablet,
            isDesktop,
            isSmallScreen,
            isWideScreen,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username is required';
              if (v.length < 3) return 'Username must be at least 3 characters';
              if (v.contains(' ')) return 'No spaces allowed';
              if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v)) {
                return 'Only letters, numbers, . or _ are allowed';
              }
              return null;
            },
          ),
          // ✅ Add this below
          SizedBox(height: 8.h),
          if (_childUsernameController.text.isNotEmpty)
            _buildChildUsernameRequirements(),

          SizedBox(height: 20.h),
          _buildFormField(
            _emailController,
            'Email',
            'Enter child\'s email address',
            Icons.email_outlined,
            isTablet,
            isDesktop,
            isSmallScreen,
            isWideScreen,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';

              final emailPattern =
                  r'^[\w\.-]+@(gmail\.com|outlook\.com|hotmail\.com|live\.com)$';
              if (!RegExp(emailPattern).hasMatch(v.trim().toLowerCase())) {
                return 'Please enter a valid Gmail, Outlook, Hotmail, or Live email';
              }

              return null;
            },
          ),
          SizedBox(height: 20.h),
          _buildFormField(
            _pinController,
            '6-Digit PIN',
            'Enter 6-digit PIN',
            Icons.lock_outline,
            isTablet,
            isDesktop,
            isSmallScreen,
            isWideScreen,
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'PIN is required';
              if (v.length != 6) return 'PIN must be exactly 6 digits';
              if (!RegExp(r'^\d{6}$').hasMatch(v))
                return 'PIN must contain only numbers';
              return null;
            },
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

  Widget _buildChildUsernameRequirements() {
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
          _buildRequirementItem(
            'At least 3 characters',
            _childUsernameHasMinLength,
          ),
          _buildRequirementItem('No spaces', _childUsernameHasNoSpaces),
          _buildRequirementItem(
            'Only letters, numbers, . or _',
            _childUsernameHasOnlyAllowedChars,
          ),
          _buildRequirementItem(
            'Username is available',
            _isChildUsernameAvailable,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    bool isTablet,
    bool isDesktop,
    bool isSmallScreen,
    bool isWideScreen, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    final fieldBorderRadius = isWideScreen
        ? 16.r
        : isDesktop
        ? 14.r
        : isTablet
        ? 12.r
        : isSmallScreen
        ? 10.r
        : 12.r;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldBorderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldBorderRadius),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldBorderRadius),
            borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
          ),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
    bool isTablet,
    bool isDesktop,
    bool isSmallScreen,
    bool isWideScreen,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF8B5CF6).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              isWideScreen
                  ? 16.r
                  : isDesktop
                  ? 14.r
                  : isTablet
                  ? 12.r
                  : 10.r,
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: isWideScreen ? 20.h : 16.h),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline),
                  SizedBox(width: 10.w),
                  Text(
                    'Set up Account',
                    style: TextStyle(
                      fontSize: isWideScreen
                          ? 20.sp
                          : isDesktop
                          ? 18.sp
                          : isTablet
                          ? 16.sp
                          : 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
