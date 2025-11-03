import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'leaderboard_entry.dart';
import '../../../widgets/custom_bottom_nav.dart';
import '../../../models/child.dart';
import '../../services/haseela_service.dart';
import '../../services/firebase_service.dart';
import '../child_home_screen.dart';
import '../child_task_view_screen.dart';
import '../wishlist_screen.dart';
import 'dart:async';
import 'my_badge_view.dart';

class LeaderboardScreen extends StatefulWidget {
  final String parentId;
  final String childId;

  const LeaderboardScreen({
    Key? key,
    required this.parentId,
    required this.childId,
  }) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> _leaderboardData = [];
  bool _isLoading = true;
  bool _showMyBadge = false;
  bool _isWeekly = true; // Weekly filter selected by default
  final HaseelaService _haseelaService = HaseelaService();
  Timer? _timer;
  DateTime? _resetTime;

  @override
  void initState() {
    super.initState();
    _loadLeaderboardData();
    _initializeTimer();
  }

  void _initializeTimer() {
    // Set reset time to end of week (Sunday 00:00)
    final now = DateTime.now();
    final daysUntilSunday = DateTime.sunday - now.weekday;
    _resetTime = now.add(
      Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday),
    );
    _resetTime = DateTime(_resetTime!.year, _resetTime!.month, _resetTime!.day);

    // Update timer every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLeaderboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all children from the same parent
      final List<Child> children = await _haseelaService.getAllChildren(
        widget.parentId,
      );

      if (children.isEmpty) {
        setState(() {
          _leaderboardData = [];
          _isLoading = false;
        });
        return;
      }

      // Calculate data for each child
      List<LeaderboardEntry> entries = [];

      for (final child in children) {
        // Get wallet
        final wallet = await FirebaseService.getChildWallet(
          widget.parentId,
          child.id,
        );

        final totalSaved = wallet?.savingBalance ?? 0.0;
        final totalSpent = wallet?.spendingBalance ?? 0.0;

        // Calculate points and level
        final points = LeaderboardEntry.calculatePoints(totalSaved);
        final currentLevel = LeaderboardEntry.calculateLevel(totalSaved);
        final progress = LeaderboardEntry.calculateProgressToNextLevel(
          totalSaved,
        );

        // Get recent purchases (spending transactions)
        List<RecentPurchase> spendingTransactions = [];
        try {
          final transactions = await FirebaseService.getChildTransactions(
            widget.parentId,
            child.id,
          );

          // Filter spending transactions and get recent ones
          spendingTransactions = transactions
              .where(
                (t) =>
                    t.type.toLowerCase() == 'spending' &&
                    t.fromWallet.toLowerCase() == 'spending',
              )
              .take(3)
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

        // Child name
        final childName = '${child.firstName} ${child.lastName}'.trim();
        if (childName.isEmpty) continue;

        entries.add(
          LeaderboardEntry(
            id: child.id,
            name: childName,
            avatarUrl: child.avatar.isNotEmpty ? child.avatar : '',
            totalSaved: totalSaved,
            totalSpent: totalSpent,
            points: points,
            currentLevel: currentLevel,
            progressToNextLevel: progress,
            recentPurchases: spendingTransactions,
            rank: 0, // Will be updated after sorting
          ),
        );
      }

      // Sort by total saved (highest first)
      entries.sort((a, b) => b.totalSaved.compareTo(a.totalSaved));

      // Update ranks
      for (int i = 0; i < entries.length; i++) {
        entries[i] = LeaderboardEntry(
          id: entries[i].id,
          name: entries[i].name,
          avatarUrl: entries[i].avatarUrl,
          totalSaved: entries[i].totalSaved,
          totalSpent: entries[i].totalSpent,
          points: entries[i].points,
          currentLevel: entries[i].currentLevel,
          progressToNextLevel: entries[i].progressToNextLevel,
          recentPurchases: entries[i].recentPurchases,
          rank: i + 1,
        );
      }

      if (mounted) {
        setState(() {
          _leaderboardData = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading leaderboard data: $e');
      if (mounted) {
        setState(() {
          _leaderboardData = [];
          _isLoading = false;
        });
      }
    }
  }

  LeaderboardEntry? get _currentUserEntry {
    try {
      return _leaderboardData.firstWhere((entry) => entry.id == widget.childId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF643FDB)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _showMyBadge
                  ? MyBadgeView(
                      entry: _currentUserEntry,
                      parentId: widget.parentId,
                      childId: widget.childId,
                    )
                  : _leaderboardData.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadLeaderboardData,
                      child: _buildBarChartView(),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    parentId: widget.parentId,
                    childId: widget.childId,
                  ),
                ),
              );
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
              break;
          }
        },
      ),
    );
  }

  Widget _buildBarChartView() {
    if (_leaderboardData.isEmpty) return SizedBox.shrink();

    final topThree = _leaderboardData.length >= 3
        ? _leaderboardData.take(3).toList()
        : _leaderboardData;
    final otherPlayers = _leaderboardData.length > 3
        ? _leaderboardData.skip(3).toList()
        : <LeaderboardEntry>[];

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 16.h),
          // Filter Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                _buildFilterButton('Weekly', true),
                SizedBox(width: 16.w),
                _buildFilterButton('Month', false),
                Spacer(),
                // Timer
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF643FDB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14.sp,
                        color: const Color(0xFF643FDB),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _getTimeRemaining(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF643FDB),
                          fontFamily: 'SPProText',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // User Rank Banner
          if (_currentUserEntry != null)
            _buildUserRankBanner(_currentUserEntry!),
          SizedBox(height: 24.h),
          // Podium for Top 3
          if (topThree.isNotEmpty) _buildPodium(topThree),
          SizedBox(height: 24.h),
          // List for Rank 4+
          if (otherPlayers.isNotEmpty) ..._buildOtherPlayersList(otherPlayers),
          SizedBox(height: 100.h), // Space for bottom nav
        ],
      ),
    );
  }

  String _getTimeRemaining() {
    if (_resetTime == null) return '00d 00h 00m';

    final now = DateTime.now();
    if (now.isAfter(_resetTime!)) {
      _initializeTimer(); // Reset timer
      return '00d 00h 00m';
    }

    final difference = _resetTime!.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    return '${days.toString().padLeft(2, '0')}d ${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
  }

  Widget _buildFilterButton(String label, bool isWeeklyButton) {
    final isSelected = isWeeklyButton == _isWeekly;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isWeekly = isWeeklyButton;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF643FDB) : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontFamily: 'SPProText',
          ),
        ),
      ),
    );
  }

  Widget _buildUserRankBanner(LeaderboardEntry entry) {
    final totalPlayers = _leaderboardData.length;
    final percentage = totalPlayers > 0
        ? ((totalPlayers - entry.rank + 1) / totalPlayers * 100).round()
        : 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9500),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF9500),
                    fontFamily: 'SPProText',
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                'You are doing better than $percentage% of other players!',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'SPProText',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> topThree) {
    // Ensure we have entries for positions 1, 2, 3
    final first = topThree.isNotEmpty ? topThree[0] : null;
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          // Avatars and names above podium
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place (left)
              if (second != null)
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          _buildAvatar(second, 60.w, false),
                          Positioned(
                            top: -8.h,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4.r,
                                  ),
                                ],
                              ),
                              child: Text(
                                '2',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF643FDB),
                                  fontFamily: 'SPProText',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        second.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C1243),
                          fontFamily: 'SPProText',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF643FDB),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${second.points} QP',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'SPProText',
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(child: SizedBox()),
              SizedBox(width: 8.w),
              // 1st place (center)
              if (first != null)
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          _buildAvatar(first, 80.w, true),
                          Positioned(
                            top: -8.h,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4.r,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.workspace_premium,
                                size: 24.sp,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        first.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C1243),
                          fontFamily: 'SPProText',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF643FDB),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${first.points} QP',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'SPProText',
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(child: SizedBox()),
              SizedBox(width: 8.w),
              // 3rd place (right)
              if (third != null)
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          _buildAvatar(third, 60.w, false),
                          Positioned(
                            top: -8.h,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4.r,
                                  ),
                                ],
                              ),
                              child: Text(
                                '3',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF643FDB),
                                  fontFamily: 'SPProText',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        third.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C1243),
                          fontFamily: 'SPProText',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF643FDB),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${third.points} QP',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'SPProText',
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(child: SizedBox()),
            ],
          ),
          SizedBox(height: 16.h),
          // Podium visual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place podium (medium height)
              if (second != null)
                Expanded(
                  child: Container(
                    height: 100.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF643FDB).withOpacity(0.3),
                          const Color(0xFF643FDB).withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.r),
                        topRight: Radius.circular(12.r),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          fontSize: 48.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SPProText',
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(child: SizedBox()),
              SizedBox(width: 4.w),
              // 1st place podium (tallest)
              if (first != null)
                Expanded(
                  child: Container(
                    height: 140.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF643FDB).withOpacity(0.3),
                          const Color(0xFF643FDB).withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.r),
                        topRight: Radius.circular(12.r),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          fontSize: 48.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SPProText',
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(child: SizedBox()),
              SizedBox(width: 4.w),
              // 3rd place podium (lowest)
              if (third != null)
                Expanded(
                  child: Container(
                    height: 80.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF643FDB).withOpacity(0.3),
                          const Color(0xFF643FDB).withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.r),
                        topRight: Radius.circular(12.r),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '3',
                        style: TextStyle(
                          fontSize: 48.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SPProText',
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(LeaderboardEntry entry, double size, bool isFirst) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: ClipOval(
        child: entry.avatarUrl.isNotEmpty
            ? Image.network(
                entry.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: size * 0.5,
                      color: Colors.grey[600],
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.person,
                  size: size * 0.5,
                  color: Colors.grey[600],
                ),
              ),
      ),
    );
  }

  List<Widget> _buildOtherPlayersList(List<LeaderboardEntry> players) {
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          padding: EdgeInsets.all(16.w),
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
            children: players.asMap().entries.map((entryMap) {
              final entry = entryMap.value;
              final index = entryMap.key;
              final isCurrentUser = entry.id == widget.childId;
              final isLast = index == players.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
                child: _buildListEntry(entry, isCurrentUser),
              );
            }).toList(),
          ),
        ),
      ),
    ];
  }

  Widget _buildListEntry(LeaderboardEntry entry, bool isCurrentUser) {
    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B7280),
                fontFamily: 'SPProText',
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrentUser
                  ? const Color(0xFF643FDB)
                  : Colors.grey[300]!,
              width: 2.w,
            ),
          ),
          child: ClipOval(
            child: entry.avatarUrl.isNotEmpty
                ? Image.network(
                    entry.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 20.sp,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 20.sp,
                      color: Colors.grey[600],
                    ),
                  ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            entry.name + (isCurrentUser ? ' (You)' : ''),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isCurrentUser
                  ? const Color(0xFF643FDB)
                  : const Color(0xFF1C1243),
              fontFamily: 'SPProText',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${entry.points} points',
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF6B7280),
            fontFamily: 'SPProText',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No siblings in the list',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'SPProText',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add more siblings to start competing!',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
              fontFamily: 'SPProText',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: const Color(0xFF1C1243),
              size: 24.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _showMyBadge ? 'My Badge' : 'Leaderboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1243),
                fontFamily: 'SPProText',
              ),
            ),
          ),
          // Toggle Button
          IconButton(
            icon: Icon(
              _showMyBadge ? Icons.bar_chart : Icons.emoji_events,
              color: const Color(0xFF643FDB),
              size: 24.sp,
            ),
            onPressed: () {
              setState(() {
                _showMyBadge = !_showMyBadge;
              });
            },
            tooltip: _showMyBadge ? 'View Leaderboard' : 'View My Badge',
          ),
        ],
      ),
    );
  }
}
