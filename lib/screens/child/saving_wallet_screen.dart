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
  bool _isSettingNewGoal =
      false; // New state to control success message visibility

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController();
    _checkGoalStatus();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _checkGoalStatus() {
    // Check if goal is already set (not default 100.0)
    _isGoalSet = widget.userWallet.savingGoal != 100.0;

    // Goal is locked if it's set but not reached
    // Goal is unlocked if it's reached (allows editing for new goal)
    _isGoalLocked = _isGoalSet && !widget.userWallet.isSavingGoalReached;

    if (_isGoalSet) {
      _goalController.text = widget.userWallet.savingGoal.toString();
    }
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
      body: SingleChildScrollView(
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

    // Update saving goal in Firebase
    final success = await FirebaseService.updateChildWalletBalance(
      widget.parentId,
      widget.childId,
      savingGoal: newGoal,
    );

    if (success) {
      // Refresh wallet data from database to get updated values
      final refreshedWallet = await FirebaseService.getChildWallet(
        widget.parentId,
        widget.childId,
      );

      if (refreshedWallet != null) {
        // Update the parent widget with fresh data
        widget.onWalletUpdated(refreshedWallet);

        // Update local state based on fresh data
        print('=== SAVE GOAL DEBUG ===');
        print('Before setState:');
        print('_isGoalSet: $_isGoalSet');
        print('_isGoalLocked: $_isGoalLocked');
        print('_isSettingNewGoal: $_isSettingNewGoal');
        print(
          'refreshedWallet.isSavingGoalReached: ${refreshedWallet.isSavingGoalReached}',
        );

        setState(() {
          _isGoalSet = true;
          _isGoalLocked = !refreshedWallet.isSavingGoalReached;
          _isSettingNewGoal = false;
        });

        print('After setState:');
        print('_isGoalSet: $_isGoalSet');
        print('_isGoalLocked: $_isGoalLocked');
        print('_isSettingNewGoal: $_isSettingNewGoal');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              refreshedWallet.isSavingGoalReached
                  ? 'Savings goal set and unlocked!'
                  : 'Savings goal set and locked!',
            ),
            backgroundColor: const Color(0xFF47C272),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Fallback if refresh fails
        final updatedWallet = widget.userWallet.copyWith(savingGoal: newGoal);
        widget.onWalletUpdated(updatedWallet);

        final isNewGoalReached = widget.userWallet.savingBalance >= newGoal;
        setState(() {
          _isGoalSet = true;
          _isGoalLocked = !isNewGoalReached;
          _isSettingNewGoal = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNewGoalReached
                  ? 'Savings goal set and unlocked!'
                  : 'Savings goal set and locked!',
            ),
            backgroundColor: const Color(0xFF47C272),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
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
    print('=== RESET GOAL DEBUG ===');
    print('Before reset:');
    print('_isGoalSet: $_isGoalSet');
    print('_isGoalLocked: $_isGoalLocked');
    print('_isSettingNewGoal: $_isSettingNewGoal');

    setState(() {
      _isGoalSet = false;
      _isGoalLocked = false;
      _isSettingNewGoal = true; // Hide success message while setting new goal
      _goalController.clear();
    });

    print('After reset:');
    print('_isGoalSet: $_isGoalSet');
    print('_isGoalLocked: $_isGoalLocked');
    print('_isSettingNewGoal: $_isSettingNewGoal');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You can now set a new savings goal!'),
        backgroundColor: const Color(0xFF47C272),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSavingsGoals() {
    final progress =
        (widget.userWallet.savingBalance / widget.userWallet.savingGoal).clamp(
          0.0,
          1.0,
        );

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
              if (!_isGoalLocked && !_isSettingNewGoal)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF47C272),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'UNLOCKED',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                )
              else if (_isGoalLocked && !_isSettingNewGoal)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6A5D),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'LOCKED',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // Goal Input Field
          TextField(
            controller: _goalController,
            enabled: !_isGoalLocked, // Disable if goal is locked
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                // Prevent leading zeros and ensure positive numbers
                if (newValue.text.isEmpty) return newValue;
                final value = double.tryParse(newValue.text);
                if (value == null || value <= 0) {
                  return oldValue;
                }
                return newValue;
              }),
            ],
            decoration: InputDecoration(
              labelText: _isGoalSet
                  ? 'Savings Goal (SAR) - ${_isGoalLocked ? "LOCKED" : "UNLOCKED"}'
                  : 'Set your savings goal (SAR)',
              hintText: _isGoalSet ? 'Goal is set' : 'Enter amount',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              prefixIcon: Icon(
                _isGoalLocked ? Icons.lock : Icons.flag,
                color: _isGoalLocked
                    ? const Color(0xFFFF6A5D)
                    : const Color(0xFF643FDB),
              ),
              suffixIcon: () {
                final shouldShow =
                    (_isGoalSet && !_isGoalLocked) ||
                    (_isSettingNewGoal && _isGoalSet);
                print('=== SAVE BUTTON DEBUG ===');
                print('_isGoalSet: $_isGoalSet');
                print('_isGoalLocked: $_isGoalLocked');
                print('_isSettingNewGoal: $_isSettingNewGoal');
                print('shouldShow: $shouldShow');

                return shouldShow
                    ? IconButton(
                        icon: Icon(Icons.check, color: const Color(0xFF47C272)),
                        onPressed: _saveGoal,
                        tooltip: 'Save Goal',
                      )
                    : null;
              }(),
            ),
            onChanged: (value) {
              print('=== TEXT CHANGED DEBUG ===');
              print('Value: "$value"');
              print('_isGoalLocked: $_isGoalLocked');
              print('_isSettingNewGoal: $_isSettingNewGoal');
              print('_isGoalSet before: $_isGoalSet');

              // Only allow changes if goal is not locked
              if (!_isGoalLocked) {
                setState(() {
                  _isGoalSet = value.isNotEmpty;
                });
                print('Updated _isGoalSet to: $_isGoalSet');
                print(
                  'Save button should show: ${(_isGoalSet && !_isGoalLocked) || (_isSettingNewGoal && _isGoalSet)}',
                );
              } else {
                print('Goal is locked, ignoring changes');
              }
            },
          ),
          SizedBox(height: 16.h),

          // Progress Bar
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
                      color: !_isGoalLocked && !_isSettingNewGoal
                          ? const Color(0xFF47C272)
                          : const Color(0xFF643FDB),
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  !_isGoalLocked && !_isSettingNewGoal
                      ? const Color(0xFF47C272)
                      : const Color(0xFF643FDB),
                ),
                minHeight: 8.h,
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

          if (!_isGoalLocked && !_isSettingNewGoal) ...[
            SizedBox(height: 16.h),
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
                    Icons.check_circle,
                    color: const Color(0xFF47C272),
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Goal reached! You can now transfer money to spending.',
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
                        vertical: 6.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    child: Text(
                      'Set New Goal',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!_isSettingNewGoal) ...[
            SizedBox(height: 16.h),
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
                      'Saving wallet is locked! Reach your goal to unlock transfers.',
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
                SizedBox(height: 2.h),
                Text(
                  _formatDate(transaction.date),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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
