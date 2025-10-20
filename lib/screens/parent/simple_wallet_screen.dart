import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/child_options.dart';
import '../../models/wallet.dart';
import '../services/firebase_service.dart';

class SimpleWalletScreen extends StatefulWidget {
  final ChildOption child;

  const SimpleWalletScreen({super.key, required this.child});

  @override
  State<SimpleWalletScreen> createState() => _SimpleWalletScreenState();
}

class _SimpleWalletScreenState extends State<SimpleWalletScreen> {
  Wallet? _wallet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  // ========================== Fetch Wallet ==========================
  Future<void> _fetchWallet() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No parent logged in.');
        setState(() => _isLoading = false);
        return;
      }

      print(
        '🔍 Fetching wallet for parent UID: ${user.uid}, child ID: ${widget.child.id}',
      );

      Wallet? wallet;

      // 1️⃣ حاول تجيب المحفظة من FirebaseService
      try {
        wallet = await FirebaseService.getChildWallet(
          user.uid,
          widget.child.id,
        );
        if (wallet != null) {
          print('✅ Wallet loaded via FirebaseService.');
        } else {
          print('⚠️ FirebaseService returned null wallet.');
        }
      } catch (e) {
        print('❌ FirebaseService error: $e');
      }

      // 2️⃣ إذا ما حصلت، جلب مباشر من Firestore
      if (wallet == null) {
        print('🔍 Trying direct Firestore access...');
        final doc = await FirebaseFirestore.instance
            .collection("Parents")
            .doc(user.uid)
            .collection("Children")
            .doc(widget.child.id)
            .collection("Wallet")
            .doc("wallet001")
            .get();

        print('📄 Document exists: ${doc.exists}');
        if (doc.exists && doc.data() != null) {
          wallet = Wallet.fromMap(doc.data()!);
          print('✅ Wallet loaded from Firestore: Total=${wallet.totalBalance}');
        } else {
          print('⚠️ No wallet found, creating a new one...');
          await _createWallet();
          return; // بعد الإنشاء، سيعاد fetch تلقائيًا
        }
      }

      setState(() {
        _wallet = wallet;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ General error fetching wallet: $e');
      setState(() => _isLoading = false);
    }
  }

  // ========================== Create Wallet ==========================
  Future<void> _createWallet() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No parent logged in for wallet creation.');
        return;
      }

      print('🔧 Creating wallet for child ID: ${widget.child.id}');

      final wallet = Wallet(
        id: 'wallet001',
        userId: widget.child.id,
        totalBalance: 0.0,
        spendingBalance: 0.0,
        savingBalance: 0.0,
        savingGoal: 100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await FirebaseService.createChildWallet(
        user.uid,
        widget.child.id,
        wallet,
      );

      if (success) {
        print('✅ Wallet created successfully.');
        await _fetchWallet(); // إعادة fetch تلقائي بعد الإنشاء
      } else {
        print('❌ Failed to create wallet via FirebaseService.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create wallet. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error creating wallet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating wallet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // ========================== Widgets ==========================
  Widget _walletWidget() {
    if (_wallet == null) {
      return _noWalletWidget();
    }

    final percent = (_wallet!.savingBalance / _wallet!.savingGoal).clamp(
      0.0,
      1.0,
    );
    Color progressColor;
    if (percent < 0.5) {
      progressColor = Colors.red;
    } else if (percent < 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // Total Balance
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade200, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '${_wallet!.totalBalance.toStringAsFixed(0)} SAR',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        // Spending & Savings
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade200, Colors.red.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Text(
                      'Spending',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${_wallet!.spendingBalance.toStringAsFixed(0)} SAR',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade200, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Text(
                      'Savings',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${_wallet!.savingBalance.toStringAsFixed(0)} SAR',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),

        // Saving Goal
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade200, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              Text(
                'Saving Goal',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '${_wallet!.savingBalance.toStringAsFixed(0)} / ${_wallet!.savingGoal.toStringAsFixed(0)} SAR',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
              SizedBox(height: 8.h),
              LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.purple[200],
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
              SizedBox(height: 8.h),
              Text(
                '${(percent * 100).toStringAsFixed(0)}% Complete',
                style: TextStyle(fontSize: 14.sp, color: Colors.purple[700]),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        // Refresh Button
        ElevatedButton(
          onPressed: _fetchWallet,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
          ),
          child: Text(
            'Refresh Wallet Data',
            style: TextStyle(fontSize: 16.sp, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _noWalletWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 60.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No Wallet Found',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            'This child doesn\'t have a wallet yet',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: _createWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
            ),
            child: Text(
              'Create Wallet',
              style: TextStyle(fontSize: 16.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ========================== Build ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.child.firstName}\'s Wallet',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _fetchWallet, child: _walletWidget()),
    );
  }
}
