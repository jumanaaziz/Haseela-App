import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/parent_profile.dart';
import '../models/child_options.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  ParentProfile? _parentProfile;
  List<ChildOption> _children = [];
  bool _isExpanded = false;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  File? _selectedImage;

  Map<String, String?> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _loadParentProfile();
    _loadChildren();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadParentProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("Parents")
          .doc("parent001")
          .get();

      if (doc.exists) {
        setState(() {
          _parentProfile = ParentProfile.fromFirestore(doc.id, doc.data()!);
          _populateControllers();
        });
      }
    } catch (e) {
      _showToast('Error loading profile: $e', ToastificationType.error);
    }
  }

  Future<void> _loadChildren() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("Parents")
          .doc("parent001")
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

  void _populateControllers() {
    if (_parentProfile != null) {
      _firstNameController.text = _parentProfile!.firstName;
      _lastNameController.text = _parentProfile!.lastName;
      _passwordController.text = _parentProfile!.password;
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
          .doc("parent001")
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
    _populateControllers();
    setState(() {
      _isEditing = false;
      _selectedImage = null;
      _fieldErrors.clear();
    });
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

  void _showToast(String message, ToastificationType type) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.fillColored,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Responsive breakpoints
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 32.w : 16.w,
            vertical: 20.h,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 600.w : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_parentProfile != null) _buildProfileSection(),
                SizedBox(height: 24.h),
                _buildChildrenSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: CircleAvatar(
                    radius: 30.r,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_parentProfile?.avatar != null
                                  ? NetworkImage(_parentProfile!.avatar!)
                                  : null)
                              as ImageProvider<Object>?,
                    child:
                        _selectedImage == null && _parentProfile?.avatar == null
                        ? Icon(Icons.person, color: Colors.white, size: 30.sp)
                        : null,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Hello, ${_parentProfile!.firstName}!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
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
                    size: 28.sp,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),
          if (_isExpanded) _buildProfileInformation(),
        ],
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

  Widget _buildChildrenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Children',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        if (_children.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Icon(Icons.child_care, size: 48.sp, color: Colors.grey[400]),
                SizedBox(height: 8.h),
                Text(
                  'No children added yet',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 130.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _children.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildAddChildCard();
                return _buildChildCard(_children[index - 1]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildChildCard(ChildOption child) {
    return Container(
      width: 100.w,
      margin: EdgeInsets.only(right: 12.w),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 25.r,
                backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                child: child.avatar != null
                    ? ClipOval(
                        child: Image.network(
                          child.avatar!,
                          width: 50.w,
                          height: 50.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) {
                            return Text(
                              child.initial,
                              style: TextStyle(
                                fontSize: 20.sp,
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
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
              ),
              SizedBox(height: 8.h),
              Text(
                child.firstName,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                child.lastName,
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddChildCard() {
    return Container(
      width: 100.w,
      margin: EdgeInsets.only(right: 12.w),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () {
            _showToast(
              'Add child functionality coming soon',
              ToastificationType.info,
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical: 10.h,
            ), // ✅ balanced
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ prevent vertical stretching
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 45.w,
                  height: 45.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: const Color(0xFF8B5CF6),
                    size: 22.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Flexible(
                  child: Text(
                    'Add Child',
                    style: TextStyle(
                      fontSize: 11.sp,
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
}
