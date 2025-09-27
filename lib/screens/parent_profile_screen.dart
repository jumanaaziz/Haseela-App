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
  
  // Field validation errors
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status bar space
              SizedBox(height: 20.h),
              
              // Profile Section
              if (_parentProfile != null) _buildProfileSection(),
              
              SizedBox(height: 20.h),
              
              // Children Section
              _buildChildrenSection(),
            ],
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
          // Header with greeting and expand/collapse
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 25.r,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: _selectedImage != null 
                            ? FileImage(_selectedImage!)
                            : (_parentProfile?.avatar != null 
                                ? NetworkImage(_parentProfile!.avatar!)
                                : null),
                        child: _selectedImage == null && (_parentProfile?.avatar == null)
                            ? Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30.sp,
                              )
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 20.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: const Color(0xFF8B5CF6),
                              size: 12.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${_parentProfile!.firstName}!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),
          
          // Expandable profile information
          if (_isExpanded) _buildProfileInformation(),
        ],
      ),
    );
  }

  Widget _buildProfileInformation() {
    return Container(
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
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          if (_isEditing) _buildEditForm() else _buildProfileDetails(),
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
      padding: EdgeInsets.only(bottom: 12.h),
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
            onChanged: (value) => _validateField('firstName', value),
            fieldType: 'firstName',
            keyboardType: TextInputType.name,
          ),
          _buildTextField(
            controller: _lastNameController,
            label: 'Last Name',
            validator: ParentProfile.validateLastName,
            onChanged: (value) => _validateField('lastName', value),
            fieldType: 'lastName',
            keyboardType: TextInputType.name,
          ),
          _buildDisplayField(
            label: 'Username',
            value: _parentProfile!.username,
          ),
          _buildDisplayField(
            label: 'Email',
            value: _parentProfile!.email,
          ),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            validator: ParentProfile.validatePassword,
            obscureText: true,
            onChanged: (value) => _validateField('password', value),
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
                child: ElevatedButton(
                  onPressed: _cancelEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayField({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Not editable',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Function(String)? onChanged,
    bool enabled = true,
    String? fieldType,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            onChanged: onChanged,
            enabled: enabled,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: 12.sp,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: enabled ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.4),
                fontSize: 12.sp,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: _fieldErrors[fieldType] != null ? Colors.red : Colors.white.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: _fieldErrors[fieldType] != null ? Colors.red : Colors.white,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: Colors.red,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: Colors.red,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              filled: true,
              fillColor: enabled ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            ),
            validator: validator,
          ),
          if (_fieldErrors[fieldType] != null)
            Padding(
              padding: EdgeInsets.only(top: 4.h, left: 12.w),
              child: Text(
                _fieldErrors[fieldType]!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10.sp,
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
                Icon(
                  Icons.child_care,
                  size: 48.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 8.h),
                Text(
                  'No children added yet',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 120.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _children.length + 1, // +1 for add button
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddChildCard();
                }
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
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
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
                          errorBuilder: (context, error, stackTrace) {
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
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                child.lastName,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
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
          onTap: () {
            _showToast('Add child functionality coming soon', ToastificationType.info);
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: const Color(0xFF8B5CF6),
                    size: 24.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Add Child',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B5CF6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
