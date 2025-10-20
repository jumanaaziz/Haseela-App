import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Lesson2MiniChallengeScreen extends StatefulWidget {
  final String childName;
  final int currentLesson;
  final int totalLessons;
  final String childId;
  final VoidCallback onComplete;

  const Lesson2MiniChallengeScreen({
    super.key,
    required this.childName,
    required this.currentLesson,
    required this.totalLessons,
    required this.childId,
    required this.onComplete,
  });

  @override
  State<Lesson2MiniChallengeScreen> createState() =>
      _Lesson2MiniChallengeScreenState();
}

class _Lesson2MiniChallengeScreenState extends State<Lesson2MiniChallengeScreen>
    with TickerProviderStateMixin {
  late AnimationController _haseelController;
  late AnimationController _celebrationController;

  List<ChallengeItem> _items = [
    ChallengeItem(
      icon: Icons.code,
      label: 'Designing a website for neighbor',
      type: ItemType.earn,
    ),
    ChallengeItem(
      icon: Icons.shopping_cart,
      label: 'Buying PlayStation card',
      type: ItemType.spend,
    ),
    ChallengeItem(
      icon: Icons.school,
      label: 'Tutoring younger student',
      type: ItemType.earn,
    ),
    ChallengeItem(
      icon: Icons.restaurant,
      label: 'Ordering food delivery',
      type: ItemType.spend,
    ),
  ];

  List<ChallengeItem> _earnItems = [];
  List<ChallengeItem> _spendItems = [];
  ChallengeItem? _selectedItem;
  bool _isCompleted = false;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _haseelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _haseelController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _checkAnswers() {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please drag an activity to "Your Choice" first!'),
          backgroundColor: const Color(0xFF3B82F6),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check if the selected item is an earning activity
    bool isCorrect = _selectedItem!.type == ItemType.earn;

    if (isCorrect) {
      setState(() {
        _isCompleted = true;
        _showCelebration = true;
      });
      _celebrationController.forward();

      Future.delayed(const Duration(seconds: 3), () {
        widget.onComplete();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Try again — think about how people create value, not just ask for it.',
          ),
          backgroundColor: const Color(0xFF3B82F6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onItemDropped(ChallengeItem item, ItemType targetType) {
    setState(() {
      // Remove from both lists first
      _earnItems.remove(item);
      _spendItems.remove(item);

      // Add to correct list
      if (targetType == ItemType.earn) {
        _earnItems.add(item);
      } else {
        _spendItems.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive design based on screen size
          final isTablet = constraints.maxWidth > 600;
          final isSmallScreen = constraints.maxWidth < 400;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFDBEAFE), // Light blue
                  Color(0xFFFEF3C7), // Light yellow
                  Color(0xFFE0F2FE), // Light teal
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Floating coin trails
                  _buildFloatingCoinTrails(),

                  // Main content
                  SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 16.w : 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressTracker(),
                        SizedBox(height: isTablet ? 32.h : 24.h),
                        _buildTitle(),
                        SizedBox(height: isTablet ? 32.h : 24.h),
                        _buildHaseelSection(),
                        SizedBox(height: isTablet ? 40.h : 32.h),
                        _buildDragDropArea(),
                        SizedBox(height: isTablet ? 40.h : 32.h),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),

                  // Celebration overlay
                  if (_showCelebration) _buildCelebrationOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressTracker() {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: const Color(0xFF475569),
            size: 28.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mini Challenge ${widget.currentLesson}/${widget.totalLessons}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                height: 8.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.currentLesson / widget.totalLessons,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: Colors.white, size: 32.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Mini Challenge: Earning vs Spending',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Sort activities into earning or spending!',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHaseelSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),

            child: Column(
              children: [
                Text(
                  '🐇 Haseel says:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '"You want to earn extra Riyals this month. Which activity shows real effort and value? Drag it to \'Your Choice\'!"',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragDropArea() {
    return Column(
      children: [
        // Floating items to drag
        Container(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              final isInEarn = _earnItems.contains(item);
              final isInSpend = _spendItems.contains(item);

              if (isInEarn || isInSpend) {
                return SizedBox(width: 0); // Hide if already placed
              }

              return Container(
                width: 100.w,
                margin: EdgeInsets.only(right: 12.w),
                child: Draggable<ChallengeItem>(
                  data: item,
                  feedback: _buildItemCard(item, isDragging: true),
                  childWhenDragging: Container(
                    width: 100.w,
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _buildItemCard(item),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 16.h),

        // Your Choice drop zone
        Container(
          width: double.infinity,
          height: 120.h,
          margin: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _selectedItem != null
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: DragTarget<ChallengeItem>(
            onWillAccept: (data) => true,
            onAccept: (item) {
              setState(() {
                _selectedItem = item;
                // Remove from other lists
                _earnItems.remove(item);
                _spendItems.remove(item);
              });
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: _selectedItem != null
                          ? const Color(0xFF3B82F6)
                          : Colors.grey[400],
                      size: 32.sp,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your Choice',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: _selectedItem != null
                            ? const Color(0xFF3B82F6)
                            : Colors.grey[600],
                      ),
                    ),
                    if (_selectedItem != null) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedItem!.icon,
                              color: const Color(0xFF3B82F6),
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _selectedItem!.label,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedItem = null;
                                });
                              },
                              child: Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),

        SizedBox(height: 32.h),

        // Drop zones
        Row(
          children: [
            Expanded(
              child: _buildDropZone('Earn Money', ItemType.earn, _earnItems),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildDropZone('Spend Money', ItemType.spend, _spendItems),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemCard(ChallengeItem item, {bool isDragging = false}) {
    return Container(
      width: 100.w,
      height: 100.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDragging ? 0.3 : 0.1),
            blurRadius: isDragging ? 20 : 8,
            offset: Offset(0, isDragging ? 10 : 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: const Color(0xFF3B82F6), size: 32.sp),
          SizedBox(height: 8.h),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone(
    String title,
    ItemType type,
    List<ChallengeItem> items,
  ) {
    return DragTarget<ChallengeItem>(
      onWillAccept: (data) => data != null,
      onAccept: (data) => _onItemDropped(data, type),
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 200.h,
          decoration: BoxDecoration(
            color: type == ItemType.earn
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? Colors.white
                  : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (type == ItemType.earn
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'Drop items here',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(8.w),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8.w,
                          mainAxisSpacing: 8.h,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _buildPlacedItem(items[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlacedItem(ChallengeItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: const Color(0xFF3B82F6), size: 20.sp),
          SizedBox(height: 4.h),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isCompleted ? null : _checkAnswers,
        icon: Icon(
          _isCompleted ? Icons.check_circle : Icons.rocket_launch,
          size: 24.sp,
        ),
        label: Text(
          _isCompleted ? 'Completed!' : 'Check My Answers',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCompleted ? Colors.grey : const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildFloatingCoinTrails() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Coin trail 1
            Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              left: MediaQuery.of(context).size.width * 0.1,
              child: Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 12.sp,
                ),
              ),
            ),
            // Coin trail 2
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              right: MediaQuery.of(context).size.width * 0.15,
              child: Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAB308),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 10.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 100.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                '🎉 Nice Work! 🎉',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'You know the difference between earning and spending!',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChallengeItem {
  final IconData icon;
  final String label;
  final ItemType type;

  ChallengeItem({required this.icon, required this.label, required this.type});
}

enum ItemType { earn, spend }
