import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user_profile.dart';
import '../../models/wallet.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 required for Firestore
import '../services/firebase_service.dart';
import 'spending_wallet_screen.dart';
import 'saving_wallet_screen.dart';
import 'transfer_screen.dart';
import '../../widgets/custom_bottom_nav.dart'; // adjust the path if needed
import 'package:haseela_app/screens/child/child_task_view_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:haseela_app/screens/auth_wrapper.dart';

class HomeScreen extends StatefulWidget {
  final String parentId;
  final String childId;

  const HomeScreen({Key? key, required this.parentId, required this.childId})
    : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isProfileExpanded = false;
  bool isLoading = true;
  File? avatarImage;
  String? avatarUrl;
  Map<String, dynamic>? _childData; // 👈 for storing child profile data
  int _navBarIndex = 0;
  // User data
  UserProfile? userProfile;
  Wallet? userWallet;

  // IDs for Firebase structure
  late final String parentId;
  late final String childId;

  @override
  void initState() {
    super.initState();
    parentId = widget.parentId;
    childId = widget.childId;

    print('🔹 INIT STATE — parentId=$parentId, childId=$childId');

    setState(() {
      isLoading = true;
    });

    Future.wait([_fetchChildProfile(), _loadUserData()])
        .then((_) {
          print('✅ Future.wait completed');
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        })
        .catchError((e) {
          print('❌ Future.wait error: $e');
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        });
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == _navBarIndex) return; // prevent unnecessary rebuild

    setState(() {
      _navBarIndex = index;
    });

    switch (index) {
      case 0:
        // Already on Home → do nothing
        break;
      case 1:
        // ✅ Navigate to Tasks
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChildTaskViewScreen(
              parentId: widget.parentId,
              childId: widget.childId,
            ),
          ),
        );
        break;
      case 2:
        // 🔸 Wishlist tab placeholder
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Wishlist coming soon')));
        break;
      case 3:
        // 🔸 Leaderboard tab placeholder
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leaderboard coming soon')),
        );
        break;
    }
  }

  Future<void> _loadUserData() async {
    try {
      print('Loading data for parent: $parentId, child: $childId');

      // 🔹 Test Firebase connection first
      await FirebaseService.testFirebaseConnection(parentId, childId);

      // 🔹 Load child profile (avatar, etc.)
      final profileData = await FirebaseService.getChildProfile(
        parentId,
        childId,
      );
      print('Profile loaded: ${profileData != null}');

      if (profileData != null &&
          profileData['avatar'] != null &&
          profileData['avatar'] != '') {
        final avatarUrl = profileData['avatar'] as String;
        print('Loading avatar from URL: $avatarUrl');
        setState(() {
          this.avatarUrl = avatarUrl;
        });
      }

      // 🔹 Load wallet
      var wallet = await FirebaseService.getChildWallet(parentId, childId);
      print('Wallet loaded: ${wallet != null}');

      if (wallet == null) {
        print('Creating new wallet for child...');
        final success = await FirebaseService.initializeChildData(
          parentId,
          childId,
        );
        print('Wallet creation success: $success');

        if (success) {
          wallet = await FirebaseService.getChildWallet(parentId, childId);
          print('New wallet loaded: ${wallet != null}');
        } else {
          throw Exception('Failed to create child wallet');
        }
      }

      // 🔹 Update state
      if (wallet != null) {
        setState(() {
          userWallet = wallet;
        });
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  Future<void> _fetchChildProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Parents')
          .doc(parentId)
          .collection('Children')
          .doc(childId)
          .get();

      if (doc.exists) {
        setState(() {
          _childData = doc.data();
        });
        print('✅ Child profile loaded: $_childData');
        isLoading = false; // ✅ Stop loading once data is ready
      } else {
        print(
          '⚠️ Child document not found for $childId under parent $parentId',
        );
      }
    } catch (e) {
      print('❌ Error fetching child profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1️⃣ Loading State
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFF1F3),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF643FDB),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: const Color(0xFF643FDB),
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2️⃣ Error State
    if (userWallet == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFF1F3),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.sp,
                color: const Color(0xFFA29EB6),
              ),
              SizedBox(height: 16.h),
              Text(
                'Failed to load data',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C1243),
                  fontFamily: 'SF Pro Text',
                ),
              ),
              SizedBox(height: 8.h),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF643FDB),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(fontFamily: 'SF Pro Text', fontSize: 16.sp),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3️⃣ Main Content State
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(),
              SizedBox(height: 24.h),
              _buildWalletCards(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0, // ✅ Home tab highlighted
        onTap: (index) {
          // The actual navigation logic is now in _onNavTap
          _onNavTap(context, index);
        },
      ),
    );
  }

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isProfileExpanded = !isProfileExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF47C272), // Green from semantic colors
              Color(0xFFB37BE7), // Light purple from overlays
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                0.1,
              ), // Used withOpacity for responsiveness
              blurRadius: 20.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Row(
              children: [
                // Profile Avatar (only editable field)
                GestureDetector(
                  onTap: () => _editProfileAvatar(),
                  child: Stack(
                    children: [
                      Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                0.1,
                              ), // Used withOpacity for responsiveness
                              blurRadius: 10.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: avatarUrl != null
                              ? Image.network(
                                  avatarUrl!,
                                  width: 60.w,
                                  height: 60.w,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback to local file if network image fails
                                    return avatarImage != null
                                        ? Image.file(
                                            avatarImage!,
                                            width: 60.w,
                                            height: 60.w,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.child_care,
                                              size: 30.sp,
                                              color: Colors.grey[600],
                                            ),
                                          );
                                  },
                                )
                              : avatarImage != null
                              ? Image.file(
                                  avatarImage!,
                                  width: 60.w,
                                  height: 60.w,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.child_care,
                                    size: 30.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF643FDB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.w),
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),

                // Name and Greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, ${_childData?['firstName'] ?? 'Child'}!",
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),

                      SizedBox(height: 4.h),
                      Text(
                        "Welcome back!",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(
                            0.9,
                          ), // Used withOpacity for responsiveness
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ),

                // Expand/Collapse Icon
                Icon(
                  isProfileExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ],
            ),

            // Expanded Profile Details
            if (isProfileExpanded) ...[
              SizedBox(height: 20.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Profile Information",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  _buildProfileField(
                    "First Name",
                    _childData?['firstName'] ?? '-',
                    isEditable: false,
                  ),
                  SizedBox(height: 12.h),
                  _buildProfileField(
                    "Username",
                    _childData?['username'] ?? '-',
                    isEditable: false,
                  ),
                  SizedBox(height: 12.h),
                  _buildProfileField(
                    "Email",
                    _childData?['email'] ?? '-',
                    isEditable: false,
                  ),
                ],
              ),
              SizedBox(height: 20.h), // Added vertical space before button
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
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(
    String label,
    String value, {
    bool isEditable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(
              0.8,
            ), // Used withOpacity for responsiveness
            fontFamily: 'SF Pro Text',
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'SF Pro Text',
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Wallets",
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
            fontFamily: 'SF Pro Text',
          ),
        ),
        SizedBox(height: 16.h),

        // Total Wallet Card (Bigger)
        _buildTotalWalletCard(),
        SizedBox(height: 16.h),

        // Spending and Saving Cards
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align cards to the top
          children: [
            Expanded(
              child: _buildWalletCard(
                "Spending",
                userWallet!.spendingBalance,
                const Color(0xFF47C272),
                Icons.shopping_cart,
                () => _navigateToSpendingWallet(),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildWalletCard(
                "Saving",
                userWallet!.savingBalance,
                const Color(0xFF643FDB),
                Icons.savings,
                () => _navigateToSavingWallet(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalWalletCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF643FDB), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.1,
            ), // Used withOpacity for responsiveness
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                    0.2,
                  ), // Used withOpacity for responsiveness
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Balance",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(
                          0.9,
                        ), // Used withOpacity for responsiveness
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                    Text(
                      "${userWallet!.totalBalance.toStringAsFixed(2)} SAR",
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToTransfer(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF643FDB),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(Icons.swap_horiz, size: 20.sp),
              label: Text(
                "Transfer Money",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(
    String title,
    double amount,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                0.05,
              ), // Used withOpacity for responsiveness
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(
                      0.1,
                    ), // Used withOpacity for responsiveness
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: color, size: 20.sp),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFFA29EB6),
                  size: 16.sp,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF718096),
                fontFamily: 'SF Pro Text',
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "${amount.toStringAsFixed(2)} SAR",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
                fontFamily: 'SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSpendingWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpendingWalletScreen(
          userWallet: userWallet!,
          parentId: parentId,
          childId: childId,
          onWalletUpdated: (updatedWallet) {
            setState(() {
              userWallet = updatedWallet;
            });
          },
        ),
      ),
    );
  }

  void _navigateToSavingWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavingWalletScreen(
          userWallet: userWallet!,
          parentId: parentId,
          childId: childId,
          onWalletUpdated: (updatedWallet) {
            setState(() {
              userWallet = updatedWallet;
            });
          },
        ),
      ),
    );
  }

  void _navigateToTransfer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransferScreen(
          userWallet: userWallet!,
          parentId: parentId,
          childId: childId,
          onWalletUpdated: (updatedWallet) {
            setState(() {
              userWallet = updatedWallet;
            });
          },
          savingGoal: userWallet!.savingGoal,
          isSavingGoalReached: userWallet!.isSavingGoalReached,
        ),
      ),
    );
  }

  void _editProfileAvatar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          "Update Avatar",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro Text',
          ),
        ),
        // IMPORTANT: Wrap content in SingleChildScrollView to handle vertical overflow
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Upload from device option
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromGallery();
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF643FDB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFF643FDB)),
                  ),
                  child: Row(
                    // Use MainAxisAlignment.start or Center (you were using Center)
                    mainAxisAlignment: MainAxisAlignment.center,
                    // Use MainAxisSize.min to prevent the Row from pushing boundaries if possible
                    mainAxisSize: MainAxisSize
                        .min, // This helps constrain the row to its children
                    children: [
                      Icon(
                        Icons.photo_camera,
                        color: const Color(0xFF643FDB),
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      // 🌟 FIX: Wrap the Text widget in an Expanded widget 🌟
                      // This forces the Text to take up the remaining space
                      // and apply automatic line wrapping if necessary.
                      Expanded(
                        child: Text(
                          "Upload Photo from Device",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF643FDB),
                            fontFamily: 'SF Pro Text',
                          ),
                          // You can also add overflow: TextOverflow.ellipsis
                          // if you prefer truncation over wrapping on extremely small screens.
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: const Color(0xFFA29EB6),
                fontFamily: 'SF Pro Text',
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          avatarImage = File(image.path);
        });

        // Upload avatar to Firebase Storage
        print('=== AVATAR UPLOAD DEBUG ===');
        print('Parent ID: $parentId');
        print('Child ID: $childId');
        print('Image path: ${image.path}');

        final avatarUrl = await FirebaseService.uploadAvatar(
          parentId,
          childId,
          File(image.path),
        );

        print('Avatar URL received: $avatarUrl');

        if (avatarUrl != null) {
          // Save avatar URL to Firebase Firestore
          print('Saving avatar URL to Firestore...');
          final success = await FirebaseService.updateChildAvatar(
            parentId,
            childId,
            avatarUrl,
          );

          print('Avatar save success: $success');

          if (success) {
            setState(() {
              this.avatarUrl = avatarUrl; // Store the uploaded URL
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Avatar uploaded and saved successfully!'),
                backgroundColor: const Color(0xFF47C272),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save avatar to database'),
                backgroundColor: const Color(0xFFFF6A5D),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload avatar'),
              backgroundColor: const Color(0xFFFF6A5D),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: const Color(0xFFFF6A5D),
        ),
      );
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('An error occurred during logout: $e'),
                      backgroundColor: const Color(0xFFFF6A5D),
                    ),
                  );
                }
              },
              icon: Icon(Icons.logout, size: 18.sp),
              label: Text('Logout', style: TextStyle(fontSize: 14.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
