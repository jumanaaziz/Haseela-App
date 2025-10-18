import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../models/user_profile.dart';
import '../../models/wallet.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'spending_wallet_screen.dart';
import 'saving_wallet_screen.dart';
import 'transfer_screen.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'package:haseela_app/screens/child/child_task_view_screen.dart';
import 'package:haseela_app/screens/child/wishlist_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:haseela_app/screens/auth_wrapper.dart';
import 'package:http/http.dart' as http;

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
  Map<String, dynamic>? _childData;
  int _navBarIndex = 0;
  UserProfile? userProfile;
  Wallet? userWallet;

  late final String parentId;
  late final String childId;

  static const String _sightengineUser = '209062856';
  static const String _sightengineSecret = '8ujGHfdeRzqJevsGymcThN4zFy3DeBxL';
  static const String _roboflowApiKey = 'VMf2fKPJgmup0N31XCxN';
  static const String _roboflowModelId = 'saudi_currencies-4ipct/5';

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
    if (index == _navBarIndex) return;

    setState(() {
      _navBarIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WishlistScreen(
              parentId: widget.parentId,
              childId: widget.childId,
            ),
          ),
        );
        break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leaderboard coming soon')),
        );
        break;
    }
  }

  Future<void> _loadUserData() async {
    try {
      print('Loading data for parent: $parentId, child: $childId');

      await FirebaseService.testFirebaseConnection(parentId, childId);

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
        isLoading = false;
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
              SizedBox(height: 16.h),
              _buildAddMoneyCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
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
              Color(0xFF47C272),
              Color(0xFFB37BE7),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                              color: Colors.black.withOpacity(0.1),
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
                                    return Container(
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.child_care,
                                        size: 30.sp,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
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
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isProfileExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ],
            ),
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
              SizedBox(height: 20.h),
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
            color: Colors.white.withOpacity(0.8),
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
        _buildTotalWalletCard(),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildAddMoneyCard() {
    return GestureDetector(
      onTap: _onAddMoneyFlow,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.add_a_photo,
                color: const Color(0xFF2D3748),
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add money to your wallet',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Scan your money to save it in your wallet',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFA29EB6),
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: const Color(0xFFA29EB6),
              size: 16.sp,
            ),
          ],
        ),
      ),
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
            color: Colors.black.withOpacity(0.1),
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
                  color: Colors.white.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.9),
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
              color: Colors.black.withOpacity(0.05),
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
                    color: color.withOpacity(0.1),
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
    // Predefined avatar URLs - REPLACE WITH YOUR FIREBASE URLS
    final List<String> avatarOptions = [
      'https://firebasestorage.googleapis.com/v0/b/haseela-95ea5.firebasestorage.app/o/avatar%2FUpstream-2.png?alt=media&token=b9f1e645-9931-4502-8bd7-2762cadf3325',
      'https://firebasestorage.googleapis.com/v0/b/haseela-95ea5.firebasestorage.app/o/avatar%2FUpstream-1.png?alt=media&token=65696973-beb7-434f-be28-b7190455632f',
      'https://firebasestorage.googleapis.com/v0/b/haseela-95ea5.firebasestorage.app/o/avatar%2FUpstream-3.png?alt=media&token=e5feeb34-2a3a-49c4-a752-b59ce5960240',
      'https://firebasestorage.googleapis.com/v0/b/haseela-95ea5.firebasestorage.app/o/avatar%2FUpstream-4.png?alt=media&token=2debb007-f86e-44a2-b09c-0057b6596322',
      'https://firebasestorage.googleapis.com/v0/b/haseela-95ea5.firebasestorage.app/o/avatar%2FUpstream-5.png?alt=media&token=c9b9bc73-bdcd-45a7-a3fe-68f611e157cb',
      'https://firebasestorage.googleapis.com/v0/b/haseela-95ea5.firebasestorage.app/o/avatar%2FUpstream-6.png?alt=media&token=c2eb55c4-bdd1-4ec0-a921-7da92cf86df4',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          "Choose Your Avatar",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro Text',
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: avatarOptions.length,
            itemBuilder: (context, index) {
              final avatarUrl = avatarOptions[index];
              final isSelected = this.avatarUrl == avatarUrl;
              
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await _selectPredefinedAvatar(avatarUrl);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF643FDB) 
                          : Colors.grey.shade300,
                      width: isSelected ? 3.w : 2.w,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF643FDB).withOpacity(0.3),
                              blurRadius: 8.r,
                              offset: Offset(0, 2.h),
                            ),
                          ]
                        : [],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            size: 30.sp,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF643FDB),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
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

  Future<void> _selectPredefinedAvatar(String avatarUrl) async {
    try {
      print('=== SELECTING PREDEFINED AVATAR ===');
      print('Parent ID: $parentId');
      print('Child ID: $childId');
      print('Avatar URL: $avatarUrl');

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF643FDB),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Updating avatar...',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Save to Firebase
      final success = await FirebaseService.updateChildAvatar(
        parentId,
        childId,
        avatarUrl,
      );

      // Close loading
      if (mounted) Navigator.pop(context);

      if (success) {
        setState(() {
          this.avatarUrl = avatarUrl;
          avatarImage = null; // Clear any local file
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: const Color(0xFF47C272),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update avatar. Please try again.'),
            backgroundColor: const Color(0xFFFF6A5D),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      
      print('Error selecting avatar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFFF6A5D),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  double? _extractAmountFromClassName(String className) {
    if (className.isEmpty) return null;

    String cleaned = className.toLowerCase().trim();
    
    print('   🔍 Parsing class name: "$className"');

    // convert text to numbers
    final Map<String, double> textToNumber = {
      'one': 1.0,
      'five': 5.0,
      'ten': 10.0,
      'fifty': 50.0,
      'hundred': 100.0,
      'fivehundred': 500.0,
      'five hundred': 500.0,
      '1': 1.0,
      '5': 5.0,
      '10': 10.0,
      '50': 50.0,
      '100': 100.0,
      '500': 500.0,
    };

    cleaned = cleaned
        .replaceAll('riyal', '')
        .replaceAll('riyals', '')
        .replaceAll('sar', '')
        .replaceAll('sr', '')
        .replaceAll('saudi', '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll('  ', ' ')
        .trim();

    print('After cleaning: "$cleaned"');

    // Check if the cleaned string matches a text number
    for (var entry in textToNumber.entries) {
      if (cleaned == entry.key || cleaned.contains(entry.key)) {
        final amount = entry.value;
        if (_isValidSaudiDenomination(amount)) {
          print('   ✅ Extracted from text: $amount SAR');
          return amount;
        }
      }
    }

    // If not a text number, try to extract numeric value
    final RegExp numberPattern = RegExp(r'(\d+)');
    final match = numberPattern.firstMatch(cleaned);

    if (match != null) {
      final String numStr = match.group(1)!;
      final double? amount = double.tryParse(numStr);
      
      if (amount != null && _isValidSaudiDenomination(amount)) {
        print('   ✅ Extracted from number: $amount SAR');
        return amount;
      } else {
        print('   ⚠️ Invalid denomination: $amount');
      }
    }

    print('   ❌ Could not extract amount');
    return null;
  }

  // Helper to validate Saudi currency denominations
  bool _isValidSaudiDenomination(double amount) {
    const validDenominations = [1.0, 5.0, 10.0, 50.0, 100.0, 500.0];
    return validDenominations.contains(amount);
  }

  Future<double?> _extractAmountWithRoboflow(File file) async {
    try {
      print('🔍 Starting Roboflow Saudi Currency Detection...');

      final List<int> imageBytes = await file.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final Uri uri = Uri.parse(
        'https://detect.roboflow.com/$_roboflowModelId'
        '?api_key=$_roboflowApiKey'
        '&confidence=50'  
        '&overlap=30',
      );

      print('Roboflow URL: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: base64Image,
      );

      print(' Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        print('API request failed with status ${response.statusCode}');
        return null;
      }

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final predictions = jsonResponse['predictions'] as List?;

      if (predictions == null || predictions.isEmpty) {
        print('No currency detected in image');
        return null;
      }

      // Store all valid detections
      List<Map<String, dynamic>> validDetections = [];

      print('\n ALL DETECTIONS:');
      for (var prediction in predictions) {
        final String className =
            (prediction['class'] as String?)?.toLowerCase() ?? '';
        final double confidence = (prediction['confidence'] ?? 0).toDouble();
        final double? amount = _extractAmountFromClassName(className);

        print('   • Class: "$className" | Amount: ${amount ?? "N/A"} SAR | Confidence: ${(confidence * 100).toStringAsFixed(1)}%');

        if (amount != null && amount > 0 && confidence >= 0.5) {
          validDetections.add({
            'amount': amount,
            'confidence': confidence,
            'className': className,
          });
        }
      }

      if (validDetections.isEmpty) {
        print('No valid currency detections found (confidence >= 50%)');
        return null;
      }

      // Sort by confidence (highest first)
      validDetections.sort((a, b) => 
        (b['confidence'] as double).compareTo(a['confidence'] as double)
      );

      // Get the most confident detection
      final bestDetection = validDetections.first;
      final double bestAmount = bestDetection['amount'];
      final double bestConfidence = bestDetection['confidence'];
      final String bestClass = bestDetection['className'];

      print('\n SELECTED: $bestAmount SAR from "$bestClass" (${(bestConfidence * 100).toStringAsFixed(1)}% confidence)');

      // If multiple detections have similar confidence, show warning
      if (validDetections.length > 1) {
        final secondBest = validDetections[1];
        final double secondAmount = secondBest['amount'];
        final double secondConfidence = secondBest['confidence'];
        
        if ((bestConfidence - secondConfidence) < 0.15) {  
          print('WARNING: Multiple similar detections found:');
          print('   1st: $bestAmount SAR (${(bestConfidence * 100).toStringAsFixed(1)}%)');
          print('   2nd: $secondAmount SAR (${(secondConfidence * 100).toStringAsFixed(1)}%)');
        }
      }

      return bestAmount;
    } catch (e, stackTrace) {
      print('Roboflow error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> _onAddMoneyFlow() async {
    try {
      final XFile? captured = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (captured == null) return;

      final File localFile = File(captured.path);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF643FDB)),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Detecting currency',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final double? amount = await _extractAmountWithRoboflow(localFile);

      if (mounted) Navigator.pop(context);

      if (amount == null || amount <= 0) {
        _showInfoDialog(
          'Unable to detect currency',
          'Please make sure:\n'
          '• The banknote is clearly visible\n'
          '• The lighting is good\n'
          '• The entire note is in frame\n'
          '• The image is not blurry',
        );
        return;
      }

      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Confirm Amount',
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Color(0xFF47C272),
                size: 48.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                '${amount.toStringAsFixed(0)} SAR',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF643FDB),
                  fontFamily: 'SF Pro Text',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Add this amount to your wallet?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Color(0xFF718096),
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFA29EB6),
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF47C272),
              ),
              child: Text(
                'Confirm',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final double newTotal = userWallet!.totalBalance + amount;
      final double newSpending = userWallet!.spendingBalance + amount;

      final bool success = await FirebaseService.updateChildWalletBalance(
        parentId,
        childId,
        totalBalance: newTotal,
        spendingBalance: newSpending,
      );

      if (success) {
        setState(() {
          userWallet = Wallet(
            id: userWallet!.id,
            userId: userWallet!.userId,
            totalBalance: newTotal,
            spendingBalance: newSpending,
            savingBalance: userWallet!.savingBalance,
            savingGoal: userWallet!.savingGoal,
            createdAt: userWallet!.createdAt,
            updatedAt: DateTime.now(),
          );
        });

        _showInfoDialog(
          'Success! 🎉',
          '${amount.toStringAsFixed(0)} SAR has been added to your spending wallet',
        );
      } else {
        _showToast('Failed to update wallet. Please try again.');
      }
    } catch (e) {
      print('❌ Add money error: $e');
      _showToast('An error occurred: $e');
    }
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 14.sp,
            color: const Color(0xFF2D3748),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
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
          actionsPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;

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