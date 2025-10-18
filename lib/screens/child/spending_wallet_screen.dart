import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/wallet.dart';
import '../../models/transaction.dart';
import '../services/firebase_service.dart';

class SpendingWalletScreen extends StatefulWidget {
  final Wallet userWallet;
  final String parentId;
  final String childId;
  final Function(Wallet) onWalletUpdated;

  const SpendingWalletScreen({
    super.key,
    required this.userWallet,
    required this.parentId,
    required this.childId,
    required this.onWalletUpdated,
  });

  @override
  State<SpendingWalletScreen> createState() => _SpendingWalletScreenState();
}

class _SpendingWalletScreenState extends State<SpendingWalletScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F3),
      appBar: AppBar(
        title: Text(
          'Spending Wallet',
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
          colors: [const Color(0xFFFF8A00), const Color(0xFFFF6A5D)],
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
                  Icons.shopping_cart,
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
                      'Spending Balance',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                    Text(
                      '${widget.userWallet.spendingBalance.toStringAsFixed(2)} SAR',
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

  Widget _buildTransactionsList() {
    return StreamBuilder<List<Transaction>>(
      stream: FirebaseService.getChildWalletTransactionsStream(
        widget.parentId,
        widget.childId,
        'spending',
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
              child: CircularProgressIndicator(color: const Color(0xFFFF8A00)),
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
                  Icons.receipt_long,
                  size: 64.sp,
                  color: const Color(0xFFA29EB6),
                ),
                SizedBox(height: 16.h),
                Text(
                  'No transactions yet',
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
      case 'food':
        return const Color(0xFFFF8A00);
      case 'gaming':
        return const Color(0xFF643FDB);
      case 'movies':
        return const Color(0xFF47C272);
      default:
        return const Color(0xFFA29EB6);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant;
      case 'gaming':
        return Icons.sports_esports;
      case 'movies':
        return Icons.movie;
      default:
        return Icons.shopping_bag;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'food':
        return 'Food & Dining';
      case 'gaming':
        return 'Gaming';
      case 'movies':
        return 'Entertainment';
      default:
        return 'Other';
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
    // Check if this is a transfer FROM spending TO saving (negative/red)
    if (transaction.fromWallet == 'spending' &&
        transaction.toWallet == 'saving') {
      return '-${transaction.amount.toStringAsFixed(2)} SAR';
    }

    // Check if this is a transfer FROM saving TO spending (positive/green)
    if (transaction.fromWallet == 'saving' &&
        transaction.toWallet == 'spending') {
      return '+${transaction.amount.toStringAsFixed(2)} SAR';
    }

    // Check if this is a wallet-to-wallet transaction from total (positive/green)
    if (transaction.fromWallet == 'total' &&
        transaction.toWallet == 'spending') {
      return '+${transaction.amount.toStringAsFixed(2)} SAR';
    }

    // Check if this is wishlist spending (negative/red)
    if (transaction.category == 'wishlist') {
      return '-${transaction.amount.toStringAsFixed(2)} SAR';
    }

    // Only show wallet-to-wallet transactions, no external spending
    return '+${transaction.amount.toStringAsFixed(2)} SAR';
  }

  Color _getTransactionAmountColor(Transaction transaction) {
    // Check if this is a transfer FROM spending TO saving (negative/red)
    if (transaction.fromWallet == 'spending' &&
        transaction.toWallet == 'saving') {
      return const Color(0xFFFF6A5D); // Red
    }

    // Check if this is a transfer FROM saving TO spending (positive/green)
    if (transaction.fromWallet == 'saving' &&
        transaction.toWallet == 'spending') {
      return const Color(0xFF47C272); // Green
    }

    // Check if this is a wallet-to-wallet transaction from total (positive/green)
    if (transaction.fromWallet == 'total' &&
        transaction.toWallet == 'spending') {
      return const Color(0xFF47C272); // Green
    }

    // Check if this is wishlist spending (negative/red)
    if (transaction.category == 'wishlist') {
      return const Color(0xFFFF6A5D); // Red
    }

    // Only show wallet-to-wallet transactions as positive/green
    return const Color(0xFF47C272); // Green
  }
}
