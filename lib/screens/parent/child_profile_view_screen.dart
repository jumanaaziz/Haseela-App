import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/child_options.dart';
import '../../models/wallet.dart';
import '../../models/transaction.dart' as app_transaction;
import '../services/firebase_service.dart';

class ChildProfileViewScreen extends StatefulWidget {
  final ChildOption child;
  final String parentId;

  const ChildProfileViewScreen({
    super.key,
    required this.child,
    required this.parentId,
  });

  @override
  State<ChildProfileViewScreen> createState() => _ChildProfileViewScreenState();
}

class _ChildProfileViewScreenState extends State<ChildProfileViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _childDetails;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Debug child information
    print('=== CHILD OBJECT DEBUG ===');
    print('Child ID: ${widget.child.id}');
    print('Child First Name: ${widget.child.firstName}');
    print('Child Username: ${widget.child.username}');
    print('Child Email: ${widget.child.email}');
    print('Child ID Type: ${widget.child.id.runtimeType}');
    print('Child ID Length: ${widget.child.id.length}');
    print('========================');

    // Set data immediately in initState
    _childDetails = {
      'firstName': widget.child.firstName,
      'username': widget.child.username,
      'email': widget.child.email ?? 'N/A',
      'pin_display': '123456', // Default PIN for now
    };
    
    
    // Also try to load from Firestore in the background
    _loadFromFirestoreInBackground();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  
  Future<void> _loadFromFirestoreInBackground() async {
    try {
      print('=== LOADING FROM FIRESTORE IN BACKGROUND ===');
      final doc = await FirebaseFirestore.instance
          .collection('Parents')
          .doc(widget.parentId)
          .collection('Children')
          .doc(widget.child.id)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists) {
        final data = doc.data();
        print('Firestore data found: $data');

        if (data != null &&
            data['firstName'] != null &&
            data['firstName'].toString().trim().isNotEmpty) {
          if (mounted) {
            setState(() {
              _childDetails = {
                'firstName': data['firstName'] ?? widget.child.firstName,
                'username': data['username'] ?? widget.child.username,
                'email': data['email'] ?? widget.child.email ?? 'N/A',
                'pin_display': data['pin_display'] ?? 'N/A',
              };
            });
            print('=== UPDATED WITH FIRESTORE DATA ===');
          }
        }
      }
    } catch (e) {
      print('Background Firestore load failed: $e');
      // Keep the immediate data we already have
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final isSmallScreen = screenHeight < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isTablet, isDesktop, isSmallScreen),
            _buildTabBar(isTablet, isDesktop, isSmallScreen),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTrackWalletTab(isTablet, isDesktop, isSmallScreen),
                  _buildAccountInfoTab(isTablet, isDesktop, isSmallScreen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, bool isDesktop, bool isSmallScreen) {
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                color: Colors.white.withOpacity(0.2),
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
                Icons.arrow_back,
                color: Colors.white,
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
          CircleAvatar(
            radius: isDesktop
                ? 30.r
                : isTablet
                ? 28.r
                : isSmallScreen
                ? 20.r
                : 25.r,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: widget.child.avatar != null
                ? ClipOval(
                    child: Image.network(
                      widget.child.avatar!,
                      width:
                          (isDesktop
                              ? 30.r
                              : isTablet
                              ? 28.r
                              : isSmallScreen
                              ? 20.r
                              : 25.r) *
                          2,
                      height:
                          (isDesktop
                              ? 30.r
                              : isTablet
                              ? 28.r
                              : isSmallScreen
                              ? 20.r
                              : 25.r) *
                          2,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) {
                        return Text(
                          widget.child.initial,
                          style: TextStyle(
                            fontSize: isDesktop
                                ? 24.sp
                                : isTablet
                                ? 22.sp
                                : isSmallScreen
                                ? 16.sp
                                : 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    widget.child.initial,
                    style: TextStyle(
                      fontSize: isDesktop
                          ? 24.sp
                          : isTablet
                          ? 22.sp
                          : isSmallScreen
                          ? 16.sp
                          : 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.child.firstName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop
                        ? 24.sp
                        : isTablet
                        ? 22.sp
                        : isSmallScreen
                        ? 18.sp
                        : 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.child.lastName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isDesktop
                        ? 16.sp
                        : isTablet
                        ? 15.sp
                        : isSmallScreen
                        ? 12.sp
                        : 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isTablet, bool isDesktop, bool isSmallScreen) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF8B5CF6),
        labelColor: const Color(0xFF8B5CF6),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: TextStyle(
          fontSize: isDesktop
              ? 16.sp
              : isTablet
              ? 15.sp
              : isSmallScreen
              ? 12.sp
              : 14.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isDesktop
              ? 16.sp
              : isTablet
              ? 15.sp
              : isSmallScreen
              ? 12.sp
              : 14.sp,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: 'Track Child Wallet'),
          Tab(text: 'Child Account Information'),
        ],
      ),
    );
  }

  Widget _buildAccountInfoTab(
    bool isTablet,
    bool isDesktop,
    bool isSmallScreen,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isDesktop
            ? 24.w
            : isTablet
            ? 20.w
            : 16.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              isDesktop
                  ? 24.w
                  : isTablet
                  ? 20.w
                  : 16.w,
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: isDesktop
                        ? 20.sp
                        : isTablet
                        ? 18.sp
                        : isSmallScreen
                        ? 16.sp
                        : 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                if (_childDetails != null) ...[
                  _buildInfoRow('First Name', _childDetails!['firstName'] ?? '', isTablet, isDesktop, isSmallScreen),
                  _buildInfoRow('Username', _childDetails!['username'] ?? '', isTablet, isDesktop, isSmallScreen),
                  _buildInfoRow('Email', _childDetails!['email'] ?? '', isTablet, isDesktop, isSmallScreen),
                  _buildInfoRow('PIN', _childDetails!['pin_display'] ?? 'N/A', isTablet, isDesktop, isSmallScreen),
                ] else ...[
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(height: 16.h),
                      Text(
                        'Loading child information...',
                        style: TextStyle(
                          fontSize: isDesktop
                              ? 16.sp
                              : isTablet
                              ? 15.sp
                              : isSmallScreen
                              ? 12.sp
                              : 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _childDetails = {
                              'firstName': widget.child.firstName,
                              'username': widget.child.username,
                              'email': widget.child.email ?? 'N/A',
                              'pin_display': '123456',
                            };
                            _plainPin = '123456';
                          });
                        },
                        child: Text(
                          'Retry Now',
                          style: TextStyle(
                            fontSize: isDesktop
                                ? 14.sp
                                : isTablet
                                ? 13.sp
                                : isSmallScreen
                                ? 11.sp
                                : 12.sp,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackWalletTab(
    bool isTablet,
    bool isDesktop,
    bool isSmallScreen,
  ) {
    if (_isLoadingWallet) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show wallet information - use Firebase data if available, otherwise show default values
    final wallet =
        _childWallet ??
        Wallet(
          id: widget.child.id,
          userId: widget.child.id,
          totalBalance: 0.0,
          spendingBalance: 0.0,
          savingBalance: 0.0,
          savingGoal: 100.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    final isDataFromFirebase = _childWallet != null;

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isDesktop
            ? 24.w
            : isTablet
            ? 20.w
            : 16.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data Source Indicator
          if (!isDataFromFirebase) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[600],
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'No wallet data found in Firebase. Showing default values.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Total Balance Card
          _buildTotalBalanceCard(wallet, isTablet, isDesktop, isSmallScreen),
          SizedBox(height: 20.h),

          // Spending and Savings Cards
          Row(
            children: [
              Expanded(
                child: _buildWalletDetail(
                  'Spending',
                  wallet.spendingBalance,
                  Icons.shopping_cart,
                  const Color(0xFFEF4444),
                  isTablet,
                  isDesktop,
                  isSmallScreen,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildWalletDetail(
                  'Savings',
                  wallet.savingBalance,
                  Icons.savings,
                  const Color(0xFF3B82F6),
                  isTablet,
                  isDesktop,
                  isSmallScreen,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 12.h : isTablet ? 10.h : isSmallScreen ? 8.h : 10.h),
          Text(
            'This feature will be implemented by your teammate',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 16.sp : isTablet ? 15.sp : isSmallScreen ? 12.sp : 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Toggle PIN visibility
  void _togglePinVisibility() {
    setState(() {
      _isPinVisible = !_isPinVisible;
    });

    // Cancel existing timer if any
    _pinAutoMaskTimer?.cancel();

    // If PIN is now visible, start auto-mask timer
    if (_isPinVisible) {
      _pinAutoMaskTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isPinVisible = false;
          });
        }
      });
    }
  }

  /// Check if PIN can be revealed (not hashed)
  bool _canRevealPin() {
    // In a real app, this would check if the PIN is stored in plaintext
    // vs hashed. For now, we assume it can be revealed if _plainPin exists
    return _plainPin != null && _plainPin!.isNotEmpty;
  }

  Widget _buildInfoRow(
    String label,
    String value,
    bool isTablet,
    bool isDesktop,
    bool isSmallScreen,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isDesktop
            ? 16.h
            : isTablet
            ? 14.h
            : isSmallScreen
            ? 10.h
            : 12.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isDesktop
                ? 120.w
                : isTablet
                ? 100.w
                : isSmallScreen
                ? 80.w
                : 90.w,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isDesktop
                    ? 14.sp
                    : isTablet
                    ? 13.sp
                    : isSmallScreen
                    ? 11.sp
                    : 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontSize: isDesktop
                    ? 14.sp
                    : isTablet
                    ? 13.sp
                    : isSmallScreen
                    ? 11.sp
                    : 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }
}
