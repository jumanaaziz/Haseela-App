import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../../models/wallet.dart';
import '../../models/transaction.dart';
import '../services/firebase_service.dart';

class SavingWalletScreen extends StatefulWidget {
  final Wallet userWallet;
  final String parentId;
  final String childId;
  final Function(Wallet) onWalletUpdated;

  const SavingWalletScreen({
    super.key,
    required this.userWallet,
    required this.parentId,
    required this.childId,
    required this.onWalletUpdated,
  });

  @override
  State<SavingWalletScreen> createState() => _SavingWalletScreenState();
}

class _SavingWalletScreenState extends State<SavingWalletScreen> {
  late TextEditingController _goalController;
  bool _isGoalSet = false;
  bool _isGoalLocked = false;
  bool _isSettingNewGoal = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController();
    _checkGoalStatus();
  }

  @override
  void didUpdateWidget(SavingWalletScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Refresh status if wallet data has changed
    if (oldWidget.userWallet.savingGoal != widget.userWallet.savingGoal ||
        oldWidget.userWallet.savingBalance != widget.userWallet.savingBalance ||
        oldWidget.userWallet.isSavingGoalReached !=
            widget.userWallet.isSavingGoalReached) {
      _checkGoalStatus();
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _checkGoalStatus() {
    setState(() {
      // Check if goal is already set (not default 100.0)
      _isGoalSet = widget.userWallet.savingGoal != 100.0;

      // Goal is locked if it's set but not reached
      // Goal is unlocked if it's reached (allows editing for new goal)
      _isGoalLocked = _isGoalSet && !widget.userWallet.isSavingGoalReached;

      if (_isGoalSet && !_isSettingNewGoal) {
        _goalController.text = widget.userWallet.savingGoal.toString();
      }

      // Don't override _isSettingNewGoal if user is actively setting a new goal
      if (!_isSettingNewGoal) {
        _isSettingNewGoal = false;
      }
    });

    print('=== GOAL STATUS CHECK ===');
    print('savingGoal: ${widget.userWallet.savingGoal}');
    print('savingBalance: ${widget.userWallet.savingBalance}');
    print('isSavingGoalReached: ${widget.userWallet.isSavingGoalReached}');
    print('_isGoalSet: $_isGoalSet');
    print('_isGoalLocked: $_isGoalLocked');
    print('_isSettingNewGoal: $_isSettingNewGoal');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F3),
      appBar: AppBar(
        title: Text(
          'Saving Wallet',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro Text',
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1243),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                _buildBalanceCard(),
                SizedBox(height: 24.h),

                // Savings Goals
                _buildSavingsGoals(),
                SizedBox(height: 24.h),

                // Transactions Header
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1243),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                SizedBox(height: 16.h),

                // Transactions List
                _buildTransactionsList(),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: const Color(0xFF47C272),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Saving goal...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF47C272), const Color(0xFFB37BE7)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.monetization_on,
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
                      'Saving Balance',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                    Text(
                      '${widget.userWallet.savingBalance.toStringAsFixed(2)} SAR',
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
        ],
      ),
    );
  }

  Future<void> _saveGoal() async {
    final parsedGoal = double.tryParse(_goalController.text);

    // Validate input - must be positive number
    if (parsedGoal == null || parsedGoal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid positive amount'),
          backgroundColor: const Color(0xFFFF6A5D),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final newGoal = parsedGoal;

    setState(() {
      _isLoading = true;
    });

    print('=== SAVING GOAL ===');
    print('New goal: $newGoal');
    print('Current balance: ${widget.userWallet.savingBalance}');

    // Calculate if goal is reached
    final isGoalReached = widget.userWallet.savingBalance >= newGoal;
    print('Is goal reached: $isGoalReached');

    // Update saving goal in Firebase
    final success = await FirebaseService.updateChildWalletBalance(
      widget.parentId,
      widget.childId,
      savingGoal: newGoal,
    );

    if (success) {
      print('Goal saved to Firebase successfully');

      // Wait a moment for Firebase to process
      await Future.delayed(Duration(milliseconds: 500));

      // Refresh wallet data from database to get updated values
      final refreshedWallet = await FirebaseService.getChildWallet(
        widget.parentId,
        widget.childId,
      );

      setState(() {
        _isLoading = false;
      });

      if (refreshedWallet != null) {
        print('Wallet refreshed from Firebase:');
        print('- savingGoal: ${refreshedWallet.savingGoal}');
        print('- savingBalance: ${refreshedWallet.savingBalance}');
        print('- isSavingGoalReached: ${refreshedWallet.isSavingGoalReached}');

        // Update the parent widget with fresh data
        widget.onWalletUpdated(refreshedWallet);

        // Update local state based on fresh data
        setState(() {
          _isGoalSet = true;
          _isGoalLocked = !refreshedWallet.isSavingGoalReached;
          _isSettingNewGoal = false;
        });

        print('Local state updated:');
        print('- _isGoalSet: $_isGoalSet');
        print('- _isGoalLocked: $_isGoalLocked');
        print('- _isSettingNewGoal: $_isSettingNewGoal');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              refreshedWallet.isSavingGoalReached
                  ? '🎉 Goal reached! Wallet unlocked!'
                  : '🔒 Goal set successfully! Wallet locked until you reach ${newGoal.toStringAsFixed(2)} SAR',
            ),
            backgroundColor: refreshedWallet.isSavingGoalReached
                ? const Color(0xFF47C272)
                : const Color(0xFF643FDB),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        print('Failed to refresh wallet from Firebase');
        // Fallback: calculate locally
        final isNewGoalReached = widget.userWallet.savingBalance >= newGoal;
        final updatedWallet = widget.userWallet.copyWith(savingGoal: newGoal);
        widget.onWalletUpdated(updatedWallet);

        setState(() {
          _isGoalSet = true;
          _isGoalLocked = !isNewGoalReached;
          _isSettingNewGoal = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNewGoalReached
                  ? '🎉 Goal reached! Wallet unlocked!'
                  : '🔒 Goal set successfully! Wallet locked.',
            ),
            backgroundColor: isNewGoalReached
                ? const Color(0xFF47C272)
                : const Color(0xFF643FDB),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });

      print('Failed to save goal to Firebase');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save goal. Please try again.'),
          backgroundColor: const Color(0xFFFF6A5D),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _resetGoal() {
    print('=== RESET GOAL ===');
    print('Before reset:');
    print('_isGoalSet: $_isGoalSet');
    print('_isGoalLocked: $_isGoalLocked');
    print('_isSettingNewGoal: $_isSettingNewGoal');

    setState(() {
      _isGoalSet = false;
      _isGoalLocked = false;
      _isSettingNewGoal = true;
      _goalController.clear();
    });

    print('After reset:');
    print('_isGoalSet: $_isGoalSet');
    print('_isGoalLocked: $_isGoalLocked');
    print('_isSettingNewGoal: $_isSettingNewGoal');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Set a new savings goal!'),
        backgroundColor: const Color(0xFF47C272),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSavingsGoals() {
    final progress = widget.userWallet.savingGoal > 0
        ? (widget.userWallet.savingBalance / widget.userWallet.savingGoal)
              .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Text(
                'Savings Goal',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C1243),
                  fontFamily: 'SF Pro Text',
                ),
              ),
              Spacer(),
              if (_isGoalSet && !_isGoalLocked && !_isSettingNewGoal)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF47C272),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_open, size: 12.sp, color: Colors.white),
                      SizedBox(width: 4.w),
                      Text(
                        'UNLOCKED',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                )
              else if (_isGoalSet && _isGoalLocked && !_isSettingNewGoal)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6A5D),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12.sp, color: Colors.white),
                      SizedBox(width: 4.w),
                      Text(
                        'LOCKED',
                        style: TextStyle(
                          fontSize: 10.sp,
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
          SizedBox(height: 16.h),

          // Goal Input Field (without suffix icon)
          TextField(
            controller: _goalController,
            enabled: !_isGoalLocked,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: _isGoalLocked
                  ? 'Savings Goal (SAR) - LOCKED'
                  : 'Set your savings goal (SAR)',
              hintText: _isGoalLocked ? 'Reach goal to unlock' : 'Enter amount',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: _isGoalLocked
                      ? const Color(0xFFFF6A5D).withOpacity(0.3)
                      : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: _isGoalLocked
                      ? const Color(0xFFFF6A5D)
                      : const Color(0xFF643FDB),
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                _isGoalLocked ? Icons.lock : Icons.flag,
                color: _isGoalLocked
                    ? const Color(0xFFFF6A5D)
                    : const Color(0xFF643FDB),
              ),
            ),
            onChanged: (value) {
              if (!_isGoalLocked) {
                setState(() {
                  // Trigger rebuild to show/hide save button
                });
              }
            },
          ),

          // Save Goal Button - Now visible and prominent
          if (!_isGoalLocked && _goalController.text.isNotEmpty) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF47C272),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Save Goal',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 16.h),

          // Progress Bar
          if (_isGoalSet) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1C1243),
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: !_isGoalLocked
                            ? const Color(0xFF47C272)
                            : const Color(0xFF643FDB),
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      !_isGoalLocked
                          ? const Color(0xFF47C272)
                          : const Color(0xFF643FDB),
                    ),
                    minHeight: 8.h,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${widget.userWallet.savingBalance.toStringAsFixed(2)} SAR / ${widget.userWallet.savingGoal.toStringAsFixed(2)} SAR',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF718096),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],

          // Status Messages
          if (_isGoalSet && !_isGoalLocked && !_isSettingNewGoal) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF47C272).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFF47C272)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration,
                    color: const Color(0xFF47C272),
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Congratulations! You reached your goal! You can now transfer money to spending.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF47C272),
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: _resetGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF47C272),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    child: Text(
                      'New Goal',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_isGoalSet && _isGoalLocked && !_isSettingNewGoal) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6A5D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFFF6A5D)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: const Color(0xFFFF6A5D), size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Saving wallet is locked! Reach your goal of ${widget.userWallet.savingGoal.toStringAsFixed(2)} SAR to unlock transfers.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFF6A5D),
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!_isGoalSet || _isSettingNewGoal) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF643FDB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFF643FDB)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF643FDB),
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Set a savings goal to start tracking your progress! Your wallet will lock until you reach it.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF643FDB),
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return StreamBuilder<List<Transaction>>(
      stream: FirebaseService.getChildWalletTransactionsStream(
        widget.parentId,
        widget.childId,
        'saving',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(40.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: CircularProgressIndicator(color: const Color(0xFF47C272)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(40.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: const Color(0xFFFF6A5D),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Error loading transactions',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFF6A5D),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(40.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 64.sp,
                  color: const Color(0xFFA29EB6),
                ),
                SizedBox(height: 16.h),
                Text(
                  'No savings transactions yet',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFA29EB6),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: transactions
              .map((transaction) => _buildTransactionItem(transaction))
              .toList(),
        );
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category Icon
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: _getCategoryColor(
                transaction.category,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _getCategoryIcon(transaction.category),
              color: _getCategoryColor(transaction.category),
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),

          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C1243),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _getCategoryName(transaction.category),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFFA29EB6),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            _getTransactionAmountText(transaction),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: _getTransactionAmountColor(transaction),
              fontFamily: 'SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'goal':
        return const Color(0xFF47C272);
      case 'bonus':
        return const Color(0xFFFF8A00);
      case 'interest':
        return const Color(0xFF643FDB);
      default:
        return const Color(0xFFA29EB6);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'goal':
        return Icons.flag;
      case 'bonus':
        return Icons.stars;
      case 'interest':
        return Icons.trending_up;
      default:
        return Icons.savings;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'goal':
        return 'Savings Goal';
      case 'bonus':
        return 'Bonus';
      case 'interest':
        return 'Interest';
      default:
        return 'Savings';
    }
  }

  String _getTransactionAmountText(Transaction transaction) {
    // Check if this is a transfer FROM saving TO spending (negative/red)
    if (transaction.fromWallet == 'saving' &&
        transaction.toWallet == 'spending') {
      return '-${transaction.amount.toStringAsFixed(2)} SAR';
    }

    // Check if this is a transfer FROM spending TO saving (positive/green)
    if (transaction.fromWallet == 'spending' &&
        transaction.toWallet == 'saving') {
      return '+${transaction.amount.toStringAsFixed(2)} SAR';
    }

    // Check if this is a wallet-to-wallet transaction from total (positive/green)
    if (transaction.fromWallet == 'total' && transaction.toWallet == 'saving') {
      return '+${transaction.amount.toStringAsFixed(2)} SAR';
    }

    // Check if this is wishlist spending from savings (negative/red)
    if (transaction.category == 'wishlist' &&
        transaction.fromWallet == 'saving') {
      return '-${transaction.amount.toStringAsFixed(2)} SAR';
    }

    // Only show wallet-to-wallet transactions, no external spending
    return '+${transaction.amount.toStringAsFixed(2)} SAR';
  }

  Color _getTransactionAmountColor(Transaction transaction) {
    // Check if this is a transfer FROM saving TO spending (negative/red)
    if (transaction.fromWallet == 'saving' &&
        transaction.toWallet == 'spending') {
      return const Color(0xFFFF6A5D); // Red
    }

    // Check if this is a transfer FROM spending TO saving (positive/green)
    if (transaction.fromWallet == 'spending' &&
        transaction.toWallet == 'saving') {
      return const Color(0xFF47C272); // Green
    }

    // Check if this is a wallet-to-wallet transaction from total (positive/green)
    if (transaction.fromWallet == 'total' && transaction.toWallet == 'saving') {
      return const Color(0xFF47C272); // Green
    }

    // Check if this is wishlist spending from savings (negative/red)
    if (transaction.category == 'wishlist' &&
        transaction.fromWallet == 'saving') {
      return const Color(0xFFFF6A5D); // Red
    }

    // Only show wallet-to-wallet transactions as positive/green
    return const Color(0xFF47C272); // Green
  }
}
