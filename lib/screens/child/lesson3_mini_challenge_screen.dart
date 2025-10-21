import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Lesson3MiniChallengeScreen extends StatefulWidget {
  final String childName;
  final int currentLesson;
  final int totalLessons;
  final String childId;
  final VoidCallback onComplete;

  const Lesson3MiniChallengeScreen({
    super.key,
    required this.childName,
    required this.currentLesson,
    required this.totalLessons,
    required this.childId,
    required this.onComplete,
  });

  @override
  State<Lesson3MiniChallengeScreen> createState() =>
      _Lesson3MiniChallengeScreenState();
}

enum ItemType { save, spend }

class DraggableItem {
  final String id;
  final String label;
  final String emoji;
  final ItemType correctType;
  final String feedback;

  DraggableItem({
    required this.id,
    required this.label,
    required this.emoji,
    required this.correctType,
    required this.feedback,
  });
}

class _Lesson3MiniChallengeScreenState extends State<Lesson3MiniChallengeScreen>
    with TickerProviderStateMixin {
  late AnimationController _haseelController;
  late AnimationController _celebrationController;
  late AnimationController _resetController;
  late AnimationController _feedbackController;
  late AnimationController _progressController;

  // Game state
  List<DraggableItem> _allItems = [];
  List<DraggableItem> _saveItems = [];
  List<DraggableItem> _spendItems = [];
  bool _isCompleted = false;
  bool _showCelebration = false;
  Map<String, bool> _zoneHighlights = {};

  // Enhanced game state
  int _score = 0;
  Map<String, bool> _itemCorrectness = {}; // Track correctness of each item
  Map<String, int> _itemAttempts = {}; // Track attempts per item

  @override
  void initState() {
    super.initState();
    _initializeItems();
    _initializeAnimations();
  }

  void _initializeItems() {
    _allItems = [
      DraggableItem(
        id: 'snack',
        label: 'Snack',
        emoji: '🍕',
        correctType: ItemType.spend,
        feedback: 'Good choice! Snacks are immediate needs 🍕.',
      ),
      DraggableItem(
        id: 'supplies',
        label: 'School Supplies',
        emoji: '📚',
        correctType: ItemType.spend,
        feedback: 'Perfect! School supplies are essential needs 📚.',
      ),
      DraggableItem(
        id: 'game',
        label: 'Game Card',
        emoji: '🎮',
        correctType: ItemType.save,
        feedback:
            'Nice! Saving for games helps you reach your goals faster 🎮.',
      ),
      DraggableItem(
        id: 'eid',
        label: 'Eid Gift',
        emoji: '🎁',
        correctType: ItemType.save,
        feedback: 'Excellent! Eid gifts are worth saving for 🎁.',
      ),
      DraggableItem(
        id: 'donation',
        label: 'Donation',
        emoji: '🤲',
        correctType: ItemType.save,
        feedback:
            'Wonderful! Charity is a meaningful way to use your Riyals 🤲.',
      ),
      DraggableItem(
        id: 'book',
        label: 'Book',
        emoji: '📖',
        correctType: ItemType.save,
        feedback: 'Smart! Books are investments in your future 📖.',
      ),
    ];
  }

  void _initializeAnimations() {
    _haseelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _haseelController.dispose();
    _celebrationController.dispose();
    _resetController.dispose();
    _feedbackController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _onItemDropped(DraggableItem item, ItemType targetType) {
    setState(() {
      // Track attempts
      _itemAttempts[item.id] = (_itemAttempts[item.id] ?? 0) + 1;

      // Remove from both lists first
      _saveItems.removeWhere((i) => i.id == item.id);
      _spendItems.removeWhere((i) => i.id == item.id);

      // Add to correct list
      if (targetType == ItemType.save) {
        _saveItems.add(item);
      } else {
        _spendItems.add(item);
      }

      // Check if correct
      bool isCorrect = item.correctType == targetType;

      // Update scoring
      if (isCorrect) {
        _score += 10; // Award points for correct answers
        _itemCorrectness[item.id] = true;
      } else {
        _itemCorrectness[item.id] = false;
        // Allow retry by removing from the list after showing feedback
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              if (targetType == ItemType.save) {
                _saveItems.removeWhere((i) => i.id == item.id);
              } else {
                _spendItems.removeWhere((i) => i.id == item.id);
              }
            });
          }
        });
      }

      // Highlight zone
      _zoneHighlights[targetType.name] = true;

      // Show enhanced feedback
      _showEnhancedFeedback(item, isCorrect);

      // Check completion
      _checkCompletion();
    });

    // Clear highlight after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _zoneHighlights[targetType.name] = false;
        });
      }
    });
  }

  void _showEnhancedFeedback(DraggableItem item, bool isCorrect) {
    _feedbackController.forward();

    // Show snackbar with enhanced styling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            AnimatedBuilder(
              animation: _feedbackController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_feedbackController.value * 0.2),
                  child: Text(isCorrect ? '✅' : '❌'),
                );
              },
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                isCorrect ? item.feedback : _getRetryMessage(item),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
            if (isCorrect) ...[
              SizedBox(width: 8.w),
              Text(
                '+10',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: isCorrect
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isCorrect ? 3 : 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );

    // Hide feedback after delay
    Future.delayed(Duration(seconds: isCorrect ? 3 : 2), () {
      if (mounted) {
        _feedbackController.reset();
      }
    });
  }

  String _getRetryMessage(DraggableItem item) {
    String correctZone = item.correctType == ItemType.save ? 'Save' : 'Spend';
    return 'Try again! That belongs in the "$correctZone" zone. Think about whether it\'s a need or want! 🤔';
  }

  void _checkCompletion() {
    int correctlyPlacedItems = 0;

    // Check save items
    for (var item in _saveItems) {
      if (item.correctType == ItemType.save) {
        correctlyPlacedItems++;
      }
    }

    // Check spend items
    for (var item in _spendItems) {
      if (item.correctType == ItemType.spend) {
        correctlyPlacedItems++;
      }
    }

    // Check if all items are placed and minimum correct answers achieved
    bool allItemsPlaced =
        _saveItems.length + _spendItems.length == _allItems.length;
    bool minimumCorrect =
        correctlyPlacedItems >= 4; // Require at least 4 out of 6 correct

    if (allItemsPlaced && minimumCorrect) {
      setState(() {
        _isCompleted = true;
        _showCelebration = true;
      });
      _celebrationController.forward();
      _progressController.forward();

      // Show completion message with score
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text('🎉'),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Level Completed! You got $correctlyPlacedItems out of ${_allItems.length} correct! Score: $_score',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 4), () {
        widget.onComplete();
      });
    } else if (allItemsPlaced && !minimumCorrect) {
      // Show message to try again
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text('🔄'),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'You got $correctlyPlacedItems out of ${_allItems.length} correct. Try again to get at least 4 correct!',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetGame() {
    _resetController.forward().then((_) {
      setState(() {
        _saveItems.clear();
        _spendItems.clear();
        _isCompleted = false;
        _showCelebration = false;
        _zoneHighlights.clear();
        // Reset enhanced game state
        _score = 0;
        _itemCorrectness.clear();
        _itemAttempts.clear();
      });
      _resetController.reverse();
      _progressController.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text('🔄'),
              SizedBox(width: 8.w),
              Text('Game reset! Try again!'),
            ],
          ),
          backgroundColor: const Color(0xFF8B5CF6),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
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
                  Color(0xFFF3E8FF), // Light purple
                  Color(0xFFFCE7F3), // Light pink
                  Color(0xFFF0FDF4), // Light green
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Floating coins animation
                  _buildFloatingCoins(),

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
                        _buildScoreAndProgress(),
                        SizedBox(height: isTablet ? 32.h : 24.h),
                        _buildHaseelSection(),
                        SizedBox(height: isTablet ? 40.h : 32.h),
                        _buildDraggableItems(isTablet, isSmallScreen),
                        SizedBox(height: isTablet ? 40.h : 32.h),
                        _buildDropZones(isTablet, isSmallScreen),
                        SizedBox(height: isTablet ? 40.h : 32.h),
                        _buildResetButton(),
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
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: const Color(0xFF8B5CF6),
            size: 24.sp,
          ),
        ),
        Expanded(
          child: Container(
            height: 8.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.currentLesson / widget.totalLessons,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Text(
          '${widget.currentLesson}/${widget.totalLessons}',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8B5CF6),
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
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 32.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Mini Challenge: Saving vs Spending',
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
            'Drag items to the right zone!',
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

  Widget _buildScoreAndProgress() {
    int correctlyPlacedItems = 0;
    for (var item in _saveItems) {
      if (item.correctType == ItemType.save) correctlyPlacedItems++;
    }
    for (var item in _spendItems) {
      if (item.correctType == ItemType.spend) correctlyPlacedItems++;
    }

    double progress = correctlyPlacedItems / _allItems.length;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '$_score',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '$correctlyPlacedItems/${_allItems.length}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Progress bar
          Container(
            height: 8.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Need at least 4 correct to complete!',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
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
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text('🐇', style: TextStyle(fontSize: 60.sp)),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '🐇 Haseel says:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '"Drag each item to the right zone! Think about what you need now vs what you can save for later."',
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

  Widget _buildDraggableItems(bool isTablet, bool isSmallScreen) {
    final availableItems = _allItems
        .where(
          (item) => !_saveItems.contains(item) && !_spendItems.contains(item),
        )
        .toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drag these items:',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: availableItems
                .map((item) => _buildDraggableItem(item))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableItem(DraggableItem item) {
    return Draggable<DraggableItem>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.1,
          child: _buildItemCard(item, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildItemCard(item)),
      child: _buildItemCard(item),
    );
  }

  Widget _buildItemCard(DraggableItem item, {bool isDragging = false}) {
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
          Text(item.emoji, style: TextStyle(fontSize: 32.sp)),
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

  Widget _buildDropZones(bool isTablet, bool isSmallScreen) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: isTablet ? 400.h : 350.h),
      child: Row(
        children: [
          Expanded(
            child: _buildDropZone(
              'Save For Later',
              '💼',
              ItemType.save,
              _saveItems,
              isTablet,
              isSmallScreen,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildDropZone(
              'Spend Now',
              '🛍️',
              ItemType.spend,
              _spendItems,
              isTablet,
              isSmallScreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone(
    String title,
    String emoji,
    ItemType type,
    List<DraggableItem> items,
    bool isTablet,
    bool isSmallScreen,
  ) {
    final isHighlighted = _zoneHighlights[type.name] ?? false;

    return DragTarget<DraggableItem>(
      onWillAccept: (data) => true,
      onAccept: (data) => _onItemDropped(data, type),
      builder: (context, candidateData, rejectedData) {
        final hasRejectedData = rejectedData.isNotEmpty;
        final hasCandidateData = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          constraints: BoxConstraints(
            minHeight: isTablet ? 200.h : 180.h,
            maxHeight: isTablet ? 400.h : 350.h,
          ),
          decoration: BoxDecoration(
            color: isHighlighted
                ? (type == ItemType.save ? Colors.green[50] : Colors.red[50])
                : hasRejectedData
                ? Colors.red[50]
                : hasCandidateData
                ? Colors.blue[50]
                : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isHighlighted
                  ? (type == ItemType.save ? Colors.green : Colors.red)
                  : hasRejectedData
                  ? Colors.red
                  : hasCandidateData
                  ? Colors.blue
                  : const Color(0xFFE2E8F0),
              width: isHighlighted || hasRejectedData || hasCandidateData
                  ? 3
                  : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isHighlighted || hasRejectedData || hasCandidateData
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1)),
                blurRadius: isHighlighted || hasRejectedData || hasCandidateData
                    ? 15
                    : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: type == ItemType.save
                      ? const Color(0xFF10B981)
                      : const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: TextStyle(fontSize: 24.sp)),
                    SizedBox(width: 8.w),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            'Drop items here',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            alignment: WrapAlignment.center,
                            children: items
                                .map((item) => _buildPlacedItem(item))
                                .toList(),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlacedItem(DraggableItem item) {
    return Container(
      width: 60.w,
      height: 60.h,
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
          Text(item.emoji, style: TextStyle(fontSize: 14.sp)),
          SizedBox(height: 2.h),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 7.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _resetGame,
        icon: Icon(Icons.refresh, size: 24.sp),
        label: Text(
          '🔄 Try Again',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
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

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isCompleted
            ? null
            : () {
                if (_saveItems.length + _spendItems.length < _allItems.length) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please place all items first!'),
                      backgroundColor: const Color(0xFF8B5CF6),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
        icon: Icon(
          _isCompleted ? Icons.check_circle : Icons.rocket_launch,
          size: 24.sp,
        ),
        label: Text(
          _isCompleted ? 'Completed!' : 'Check My Answers',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCompleted ? Colors.grey : const Color(0xFF8B5CF6),
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

  Widget _buildFloatingCoins() {
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
                  color: Colors.amber[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '﷼',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              ),
            ),
            // Coin trail 2
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              right: MediaQuery.of(context).size.width * 0.15,
              child: Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  color: Colors.amber[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '﷼',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
                  ),
                ),
              ),
            ),
            // Coin trail 3
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.3,
              left: MediaQuery.of(context).size.width * 0.2,
              child: Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  color: Colors.amber[400],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '﷼',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
                  ),
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
          child: AnimatedBuilder(
            animation: _celebrationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _celebrationController.value,
                child: Container(
                  padding: EdgeInsets.all(32.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎉', style: TextStyle(fontSize: 60.sp)),
                      SizedBox(height: 16.h),
                      Text(
                        'Excellent Work!',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'You\'ve mastered saving vs spending!',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
