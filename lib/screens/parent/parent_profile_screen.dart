import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';
import '../../models/parent_profile.dart';
import '../../models/child_options.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../parent/task_management_screen.dart';
import '../auth_wrapper.dart';
import 'setup_child_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  ParentProfile? _parentProfile;
  List<ChildOption> _children = [];
  String _parentUsername = ''; // ✅ store parent's username from Firestore
  bool _isExpanded = false;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  File? _selectedImage;

  Map<String, String?> _fieldErrors = {};

  /// ✅ Shortcut to get current logged-in UID
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadParentProfile();
    _loadChildren();
  }

  // Fill the editing controllers from the loaded _parentProfile.
  void _populateControllers() {
    if (_parentProfile == null) return;
    _firstNameController.text = _parentProfile!.firstName;
    _lastNameController.text = _parentProfile!.lastName;
    _passwordController.text = _parentProfile!.password; // if you store it
  }

  Future<void> _loadParentProfile() async {
    try {
      // ✅ Fetch parent document
      final doc = await FirebaseFirestore.instance
          .collection("Parents")
          .doc(_uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        setState(() {
          // Load parent profile object (existing behavior)
          _parentProfile = ParentProfile.fromFirestore(doc.id, data);
          _parentUsername = data['username'] ?? '';

          // ✅ Also extract parent username for child setup flow
          _parentUsername = data['username'] ?? '';
        });
      }
    } catch (e) {
      _showToast('Error loading profile: $e', ToastificationType.error);
    }
    _populateControllers();
  }

  Future<void> _loadChildren() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("Parents")
          .doc(_uid)
          .collection("Children")
          .get();

      setState(() {
        _children = snap.docs
            .map((doc) => ChildOption.fromFirestore(doc.id, doc.data()))
            .where((c) => c.firstName.trim().isNotEmpty)
            .toList();
      });
    } catch (e) {
      _showToast('Error loading children: $e', ToastificationType.error);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final updatedProfile = _parentProfile!.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection("Parents")
          .doc(_uid) // ✅ use UID instead of "parent001"
          .update(updatedProfile.toFirestore());

      setState(() {
        _parentProfile = updatedProfile;
        _isEditing = false;
      });

      _showToast('Profile updated successfully', ToastificationType.success);
    } catch (e) {
      _showToast('Error updating profile: $e', ToastificationType.error);
    }
  }

  void _cancelEdit() {
    _populateControllers(); // 👈 restore form fields to current profile
    setState(() {
      _isEditing = false;
      _selectedImage = null;
      _fieldErrors.clear();
    });
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

  void _showSetupChildDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SetupChildScreen(parentId: _uid, parentUsername: _parentUsername),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Already on Profile
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TaskManagementScreen()),
        );
        break;
      case 2:
        _showToast('Wishlist coming soon', ToastificationType.info);
        break;
      case 3:
        _showToast('Leaderboard coming soon', ToastificationType.info);
        break;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showToast('Error picking image: $e', ToastificationType.error);
    }
  }

  void _validateField(String fieldType, String value) {
    String? errorMessage;

    switch (fieldType) {
      case 'firstName':
        errorMessage = ParentProfile.validateFirstName(value);
        break;
      case 'lastName':
        errorMessage = ParentProfile.validateLastName(value);
        break;
      case 'password':
        errorMessage = ParentProfile.validatePassword(value);
        break;
    }

    setState(() {
      _fieldErrors[fieldType] = errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final isSmallScreen = screenHeight < 600;

    // 🧠 If _parentProfile is still null, show a loading screen
    if (_parentProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ Once data is loaded, build the actual UI
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
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
                  ? 800.w
                  : isTablet
                  ? 600.w
                  : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileSection(isTablet, isDesktop, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16.h : 24.h),
                _buildChildrenSection(isTablet, isDesktop, isSmallScreen),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  Widget _buildProfileInformation() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!_isEditing)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: Icon(Icons.edit, color: Colors.white, size: 16.sp),
                  label: Text(
                    'Edit',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          _isEditing ? _buildEditForm() : _buildProfileDetails(),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    return Column(
      children: [
        _buildDetailRow('First Name', _parentProfile!.firstName),
        _buildDetailRow('Last Name', _parentProfile!.lastName),
        _buildDetailRow('Username', _parentProfile!.username),
        _buildDetailRow('Email', _parentProfile!.email),
        _buildDetailRow('Phone Number', _parentProfile!.phoneNumber),
        SizedBox(height: 20.h),
        // Logout button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showLogoutDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            icon: Icon(Icons.logout, size: 18.sp),
            label: Text(
              'Logout',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
    bool isTablet,
    bool isDesktop,
    bool isSmallScreen,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 24.r : 20.r),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(
              isDesktop
                  ? 24.w
                  : isTablet
                  ? 20.w
                  : 16.w,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: CircleAvatar(
                    radius: isDesktop
                        ? 40.r
                        : isTablet
                        ? 35.r
                        : isSmallScreen
                        ? 25.r
                        : 30.r,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_parentProfile?.avatar != null
                                  ? NetworkImage(_parentProfile!.avatar!)
                                  : null)
                              as ImageProvider<Object>?,
                    child:
                        _selectedImage == null &&
                            (_parentProfile?.avatar == null)
                        ? Icon(
                            Icons.person,
                            color: Colors.white,
                            size: isDesktop
                                ? 40.sp
                                : isTablet
                                ? 35.sp
                                : isSmallScreen
                                ? 25.sp
                                : 30.sp,
                          )
                        : null,
                  ),
                ),
                SizedBox(width: isDesktop ? 16.w : 12.w),
                Expanded(
                  child: Text(
                    'Hello, ${_parentProfile!.firstName}!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop
                          ? 24.sp
                          : isTablet
                          ? 22.sp
                          : isSmallScreen
                          ? 16.sp
                          : 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: isDesktop
                        ? 32.sp
                        : isTablet
                        ? 30.sp
                        : isSmallScreen
                        ? 24.sp
                        : 28.sp,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),

          // 👇 Expandable Profile Info / Edit Section
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop
                    ? 24.w
                    : isTablet
                    ? 20.w
                    : 16.w,
                vertical: 8.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 18.sp : 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isEditing)
                        TextButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                          label: Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktop ? 14.sp : 12.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  _isEditing ? _buildEditForm() : _buildProfileDetails(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _firstNameController,
            label: 'First Name',
            validator: ParentProfile.validateFirstName,
            onChanged: (v) => _validateField('firstName', v),
            fieldType: 'firstName',
          ),
          _buildTextField(
            controller: _lastNameController,
            label: 'Last Name',
            validator: ParentProfile.validateLastName,
            onChanged: (v) => _validateField('lastName', v),
            fieldType: 'lastName',
          ),
          _buildDisplayField(
            label: 'Username',
            value: _parentProfile!.username,
          ),
          _buildDisplayField(label: 'Email', value: _parentProfile!.email),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            validator: ParentProfile.validatePassword,
            obscureText: true,
            onChanged: (v) => _validateField('password', v),
            fieldType: 'password',
          ),
          _buildDisplayField(
            label: 'Phone Number',
            value: _parentProfile!.phoneNumber,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF8B5CF6),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    String? fieldType,
    TextInputType? keyboardType,
    bool obscureText = false,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        style: TextStyle(color: Colors.white, fontSize: 12.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12.sp,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
              color: _fieldErrors[fieldType] != null
                  ? Colors.red
                  : Colors.white.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
              color: _fieldErrors[fieldType] != null
                  ? Colors.red
                  : Colors.white,
            ),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDisplayField({required String label, required String value}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenSection(
    bool isTablet,
    bool isDesktop,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Children',
          style: TextStyle(
            fontSize: isDesktop
                ? 22.sp
                : isTablet
                ? 20.sp
                : isSmallScreen
                ? 16.sp
                : 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(
          height: isDesktop
              ? 16.h
              : isTablet
              ? 14.h
              : isSmallScreen
              ? 10.h
              : 12.h,
        ),
        if (_children.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              isDesktop
                  ? 32.w
                  : isTablet
                  ? 24.w
                  : isSmallScreen
                  ? 16.w
                  : 20.w,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                isDesktop
                    ? 16.r
                    : isTablet
                    ? 14.r
                    : isSmallScreen
                    ? 10.r
                    : 12.r,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.child_care,
                  size: isDesktop
                      ? 64.sp
                      : isTablet
                      ? 56.sp
                      : isSmallScreen
                      ? 40.sp
                      : 48.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(
                  height: isDesktop
                      ? 12.h
                      : isTablet
                      ? 10.h
                      : isSmallScreen
                      ? 6.h
                      : 8.h,
                ),
                Text(
                  'No children added yet',
                  style: TextStyle(
                    fontSize: isDesktop
                        ? 18.sp
                        : isTablet
                        ? 16.sp
                        : isSmallScreen
                        ? 12.sp
                        : 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(
                  height: isDesktop
                      ? 20.h
                      : isTablet
                      ? 16.h
                      : isSmallScreen
                      ? 12.h
                      : 16.h,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SetupChildScreen(
                            parentId: _uid, // parent Firestore document ID
                            parentUsername:
                                _parentUsername, // parent's username
                          ),
                        ),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0xFF8B5CF6).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
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
                      padding: EdgeInsets.symmetric(
                        vertical: isDesktop
                            ? 16.h
                            : isTablet
                            ? 14.h
                            : isSmallScreen
                            ? 10.h
                            : 12.h,
                        horizontal: isDesktop
                            ? 24.w
                            : isTablet
                            ? 20.w
                            : isSmallScreen
                            ? 16.w
                            : 20.w,
                      ),
                    ),
                    icon: Icon(
                      Icons.person_add,
                      size: isDesktop
                          ? 20.sp
                          : isTablet
                          ? 18.sp
                          : isSmallScreen
                          ? 14.sp
                          : 16.sp,
                    ),
                    label: Text(
                      'Set up child account',
                      style: TextStyle(
                        fontSize: isDesktop
                            ? 16.sp
                            : isTablet
                            ? 15.sp
                            : isSmallScreen
                            ? 12.sp
                            : 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isWideScreen = screenWidth > 800;
              final cardHeight = isWideScreen
                  ? 180.h
                  : isDesktop
                  ? 160.h
                  : isTablet
                  ? 140.h
                  : isSmallScreen
                  ? 110.h
                  : 130.h;

              return SizedBox(
                height: cardHeight,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _children.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0)
                      return _buildAddChildCard(
                        isTablet,
                        isDesktop,
                        isSmallScreen,
                        isWideScreen,
                      );
                    return _buildChildCard(
                      _children[index - 1],
                      isTablet,
                      isDesktop,
                      isSmallScreen,
                      isWideScreen,
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildChildCard(
    ChildOption child,
    bool isTablet,
    bool isDesktop,
    bool isSmallScreen,
    bool isWideScreen,
  ) {
    // Calculate responsive dimensions
    final cardWidth = isWideScreen
        ? 140.w
        : isDesktop
        ? 120.w
        : isTablet
        ? 110.w
        : isSmallScreen
        ? 90.w
        : 100.w;
    final cardPadding = isWideScreen
        ? 18.w
        : isDesktop
        ? 16.w
        : isTablet
        ? 14.w
        : isSmallScreen
        ? 8.w
        : 10.w;
    final avatarRadius = isWideScreen
        ? 40.r
        : isDesktop
        ? 35.r
        : isTablet
        ? 30.r
        : isSmallScreen
        ? 20.r
        : 25.r;
    final borderRadius = isWideScreen
        ? 18.r
        : isDesktop
        ? 16.r
        : isTablet
        ? 14.r
        : isSmallScreen
        ? 10.r
        : 12.r;
    final marginRight = isWideScreen
        ? 18.w
        : isDesktop
        ? 16.w
        : isTablet
        ? 14.w
        : isSmallScreen
        ? 10.w
        : 12.w;
    final spacing = isWideScreen
        ? 14.h
        : isDesktop
        ? 12.h
        : isTablet
        ? 10.h
        : isSmallScreen
        ? 6.h
        : 8.h;
    final nameFontSize = isWideScreen
        ? 18.sp
        : isDesktop
        ? 16.sp
        : isTablet
        ? 14.sp
        : isSmallScreen
        ? 10.sp
        : 12.sp;
    final lastNameFontSize = isWideScreen
        ? 16.sp
        : isDesktop
        ? 14.sp
        : isTablet
        ? 12.sp
        : isSmallScreen
        ? 8.sp
        : 10.sp;
    final initialFontSize = isWideScreen
        ? 32.sp
        : isDesktop
        ? 28.sp
        : isTablet
        ? 24.sp
        : isSmallScreen
        ? 16.sp
        : 20.sp;

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: marginRight),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                child: child.avatar != null
                    ? ClipOval(
                        child: Image.network(
                          child.avatar!,
                          width: avatarRadius * 2,
                          height: avatarRadius * 2,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) {
                            return Text(
                              child.initial,
                              style: TextStyle(
                                fontSize: initialFontSize,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF8B5CF6),
                              ),
                            );
                          },
                        ),
                      )
                    : Text(
                        child.initial,
                        style: TextStyle(
                          fontSize: initialFontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
              ),
              SizedBox(height: spacing),
              Flexible(
                child: Text(
                  child.firstName,
                  style: TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 2.h),
              Flexible(
                child: Text(
                  child.lastName,
                  style: TextStyle(
                    fontSize: lastNameFontSize,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddChildCard(
    bool isTablet,
    bool isDesktop,
    bool isSmallScreen,
    bool isWideScreen,
  ) {
    // Calculate responsive dimensions
    final cardWidth = isWideScreen
        ? 140.w
        : isDesktop
        ? 120.w
        : isTablet
        ? 110.w
        : isSmallScreen
        ? 90.w
        : 100.w;
    final cardPadding = isWideScreen
        ? 18.w
        : isDesktop
        ? 16.w
        : isTablet
        ? 14.w
        : isSmallScreen
        ? 8.w
        : 10.w;
    final iconSize = isWideScreen
        ? 70.w
        : isDesktop
        ? 60.w
        : isTablet
        ? 55.w
        : isSmallScreen
        ? 40.w
        : 45.w;
    final borderRadius = isWideScreen
        ? 18.r
        : isDesktop
        ? 16.r
        : isTablet
        ? 14.r
        : isSmallScreen
        ? 10.r
        : 12.r;
    final marginRight = isWideScreen
        ? 18.w
        : isDesktop
        ? 16.w
        : isTablet
        ? 14.w
        : isSmallScreen
        ? 10.w
        : 12.w;
    final spacing = isWideScreen
        ? 10.h
        : isDesktop
        ? 8.h
        : isTablet
        ? 7.h
        : isSmallScreen
        ? 4.h
        : 6.h;
    final textFontSize = isWideScreen
        ? 16.sp
        : isDesktop
        ? 14.sp
        : isTablet
        ? 13.sp
        : isSmallScreen
        ? 9.sp
        : 11.sp;
    final iconFontSize = isWideScreen
        ? 32.sp
        : isDesktop
        ? 28.sp
        : isTablet
        ? 24.sp
        : isSmallScreen
        ? 18.sp
        : 22.sp;

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: marginRight),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SetupChildScreen(
                  parentId: _uid,
                  parentUsername: _parentUsername,
                ),
              ),
            );
          },

          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: const Color(0xFF8B5CF6),
                    size: iconFontSize,
                  ),
                ),
                SizedBox(height: spacing),
                Flexible(
                  child: Text(
                    'Add Child',
                    style: TextStyle(
                      fontSize: textFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B5CF6),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 24.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                try {
                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;

                  // ✅ Return to AuthWrapper directly
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false,
                  );
                } catch (e) {
                  _showToast('Error logging out: $e', ToastificationType.error);
                }
              },
              icon: const Icon(Icons.logout, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              label: Text('Logout', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        );
      },
    );
  }
}
