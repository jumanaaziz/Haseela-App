import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'leaderboard_entry.dart';
import '../../services/firebase_service.dart';

class MyBadgeView extends StatefulWidget {
  final LeaderboardEntry? entry;
  final String parentId;
  final String childId;

  const MyBadgeView({
    Key? key,
    this.entry,
    required this.parentId,
    required this.childId,
  }) : super(key: key);

  @override
  State<MyBadgeView> createState() => _MyBadgeViewState();
}

class _MyBadgeViewState extends State<MyBadgeView> {
  LeaderboardEntry? _entry;
  bool _isLoading = true;
  List<RecentPurchase> _allPurchases = [];

  @override
  void initState() {
    super.initState();
    _loadMyBadgeData();
  }

  Future<void> _loadMyBadgeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get wallet
      final wallet = await FirebaseService.getChildWallet(
        widget.parentId,
        widget.childId,
      );

      final totalSaved = wallet?.savingBalance ?? 0.0;
      final totalSpent = wallet?.spendingBalance ?? 0.0;

      // Calculate points and level
      final points = LeaderboardEntry.calculatePoints(totalSaved);
      final currentLevel = LeaderboardEntry.calculateLevel(totalSaved);
      final progress = LeaderboardEntry.calculateProgressToNextLevel(
        totalSaved,
      );

      // Get all purchases
      try {
        final transactions = await FirebaseService.getChildTransactions(
          widget.parentId,
          widget.childId,
        );

        _allPurchases = transactions
            .where(
              (t) =>
                  t.type.toLowerCase() == 'spending' &&
                  t.fromWallet.toLowerCase() == 'spending',
            )
            .map(
              (t) => RecentPurchase(
                description: t.description,
                amount: t.amount,
                date: t.date,
              ),
            )
            .toList();
      } catch (e) {
        print('Error loading transactions: $e');
      }

      // Get child name from entry or create default
      final name = widget.entry?.name ?? 'You';
      final avatarUrl = widget.entry?.avatarUrl ?? '';

      setState(() {
        _entry = LeaderboardEntry(
          id: widget.childId,
          name: name,
          avatarUrl: avatarUrl,
          totalSaved: totalSaved,
          totalSpent: totalSpent,
          points: points,
          currentLevel: currentLevel,
          progressToNextLevel: progress,
          recentPurchases: _allPurchases,
          rank: 0,
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading badge data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF643FDB)),
        ),
      );
    }

    if (_entry == null) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey[600],
            fontFamily: 'SPProText',
          ),
        ),
      );
    }

    final nextLevelThreshold = LeaderboardEntry.getNextLevelThreshold(
      _entry!.totalSaved,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Large Badge Icon
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: _getBadgeColor(_entry!.currentLevel).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getBadgeColor(_entry!.currentLevel),
                width: 4.w,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.emoji_events,
                size: 60.sp,
                color: _getBadgeColor(_entry!.currentLevel),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Level Text
          Text(
            'Level ${_entry!.currentLevel}',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1243),
              fontFamily: 'SPProText',
            ),
          ),
          SizedBox(height: 8.h),

          // Points
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars, size: 24.sp, color: const Color(0xFFFFD700)),
              SizedBox(width: 8.w),
              Text(
                '${_entry!.points} ${_entry!.points == 1 ? 'point' : 'points'}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                  fontFamily: 'SPProText',
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),

          // Progress to Next Level
          if (nextLevelThreshold != null) ...[
            Text(
              'Progress to Level ${_entry!.currentLevel + 1}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1243),
                fontFamily: 'SPProText',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '${_entry!.totalSaved.toStringAsFixed(0)} / ${nextLevelThreshold.toStringAsFixed(0)} SAR',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF6B7280),
                fontFamily: 'SPProText',
              ),
            ),
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: LinearProgressIndicator(
                value: _entry!.progressToNextLevel,
                minHeight: 24.h,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF643FDB),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFF47C272).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFF47C272), width: 2.w),
              ),
              child: Text(
                'Max Level Achieved! 🏆',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF47C272),
                  fontFamily: 'SPProText',
                ),
              ),
            ),
          ],
          SizedBox(height: 32.h),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Saved',
                  _entry!.totalSaved,
                  const Color(0xFF47C272),
                  Icons.account_balance_wallet,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  'Total Spent',
                  _entry!.totalSpent,
                  const Color(0xFFFF6B6B),
                  Icons.shopping_cart,
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),

          // All Purchases Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
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
                Text(
                  'Purchase History',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1243),
                    fontFamily: 'SPProText',
                  ),
                ),
                SizedBox(height: 16.h),
                if (_allPurchases.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.h),
                      child: Text(
                        'No purchases yet',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[500],
                          fontFamily: 'SPProText',
                        ),
                      ),
                    ),
                  )
                else
                  ..._allPurchases.map(
                    (purchase) => Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.shopping_bag,
                              size: 20.sp,
                              color: const Color(0xFF643FDB),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  purchase.description,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1C1243),
                                    fontFamily: 'SPProText',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  purchase.formattedDate,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF6B7280),
                                    fontFamily: 'SPProText',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${purchase.amount.toStringAsFixed(0)} SAR',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF6B6B),
                              fontFamily: 'SPProText',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24.sp, color: color),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF6B7280),
                  fontFamily: 'SPProText',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'SPProText',
            ),
          ),
          Text(
            'SAR',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
              fontFamily: 'SPProText',
            ),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(int level) {
    final colors = [
      const Color(0xFFE5E7EB),
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
      const Color(0xFF643FDB),
    ];
    return level < colors.length ? colors[level] : colors[colors.length - 1];
  }
}
