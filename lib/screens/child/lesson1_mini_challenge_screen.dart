import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Lesson1MiniChallengeScreen extends StatefulWidget {
  final String childName;
  final int currentLesson;
  final int totalLessons;
  final String childId;
  final VoidCallback onComplete;

  const Lesson1MiniChallengeScreen({
    super.key,
    required this.childName,
    required this.currentLesson,
    required this.totalLessons,
    required this.childId,
    required this.onComplete,
  });

  @override
  State<Lesson1MiniChallengeScreen> createState() =>
      _Lesson1MiniChallengeScreenState();
}

class _Lesson1MiniChallengeScreenState extends State<Lesson1MiniChallengeScreen>
    with TickerProviderStateMixin {
  late AnimationController _haseelController;
  late AnimationController _coinController;
  late AnimationController _celebrationController;

  List<ChoiceOption> _options = [
    ChoiceOption(
      icon: '🍕',
      label: 'Pizza slice from school canteen',
      isSelected: false,
    ),
    ChoiceOption(icon: '🎮', label: 'Mobile game credit', isSelected: false),
    ChoiceOption(icon: '👟', label: 'New sneakers', isSelected: false),
    ChoiceOption(icon: '📚', label: 'School supplies', isSelected: false),
    ChoiceOption(icon: '💾', label: 'Save for bigger goal', isSelected: false),
    ChoiceOption(
      icon: '💸',
      label: 'Spend it all right away — you earned it!',
      isSelected: false,
    ),
    ChoiceOption(
      icon: '🤝',
      label: 'Give it to a friend to handle for you',
      isSelected: false,
    ),
  ];

  bool _isCompleted = false;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _haseelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _haseelController.dispose();
    _coinController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _checkAnswers() {
    final selectedOptions = _options
        .where((option) => option.isSelected)
        .toList();
    final selectedCount = selectedOptions.length;

    // Check if user selected good choices (first 5 options) and avoided bad choices (last 2)
    final goodChoices = selectedOptions
        .where((option) => _options.indexOf(option) < 5)
        .length;
    final badChoices = selectedOptions
        .where((option) => _options.indexOf(option) >= 5)
        .length;

    if (selectedCount >= 3 && goodChoices >= 3 && badChoices == 0) {
      setState(() {
        _isCompleted = true;
        _showCelebration = true;
      });
      _celebrationController.forward();

      Future.delayed(const Duration(seconds: 3), () {
        widget.onComplete();
      });
    } else if (badChoices > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'That might not help you reach your goals — think about balance between fun and saving.',
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Think about what you could realistically buy with 20 Riyals. Select at least 3 options.',
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleOption(int index) {
    setState(() {
      _options[index].isSelected = !_options[index].isSelected;
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
                  Color(0xFFE0F2FE), // Light teal
                  Color(0xFFFEF3C7), // Light yellow
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
                        _buildHaseelSection(),
                        SizedBox(height: isTablet ? 40.h : 32.h),
                        _buildChallengeArea(),
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
                        colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
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
          colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on, color: Colors.white, size: 32.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Mini Challenge: What Is Money?',
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
            'Let\'s test what you learned about money!',
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
          // Haseel character placeholder
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
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
                  '"You received 30 Riyals for helping your mom. What would you do with this money? Choose wisely — think about balance!"',
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

  Widget _buildChallengeArea() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Options:',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Tap at least 3 things you could buy with one coin:',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 20.h),
          ...List.generate(_options.length, (index) {
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              child: GestureDetector(
                onTap: () => _toggleOption(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: _options[index].isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: _options[index].isSelected
                          ? const Color(0xFF10B981)
                          : Colors.white.withOpacity(0.3),
                      width: _options[index].isSelected ? 3 : 2,
                    ),
                    boxShadow: _options[index].isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          color: _options[index].isSelected
                              ? const Color(0xFF10B981)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(
                            _options[index].icon,
                            style: TextStyle(fontSize: 24.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Text(
                          _options[index].label,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: _options[index].isSelected
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                          ),
                        ),
                      ),
                      if (_options[index].isSelected)
                        Container(
                          width: 30.w,
                          height: 30.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Selected: ${_options.where((option) => option.isSelected).length}/3 minimum',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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
            // Floating coin 1
            AnimatedBuilder(
              animation: _coinController,
              builder: (context, child) {
                return Positioned(
                  top:
                      MediaQuery.of(context).size.height * 0.1 +
                      (30 * _coinController.value),
                  left:
                      MediaQuery.of(context).size.width * 0.1 +
                      (20 * _coinController.value),
                  child: Opacity(
                    opacity: 0.6,
                    child: Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Floating coin 2
            AnimatedBuilder(
              animation: _coinController,
              builder: (context, child) {
                return Positioned(
                  top:
                      MediaQuery.of(context).size.height * 0.3 +
                      (25 * (1 - _coinController.value)),
                  right:
                      MediaQuery.of(context).size.width * 0.15 +
                      (15 * (1 - _coinController.value)),
                  child: Opacity(
                    opacity: 0.5,
                    child: Container(
                      width: 25.w,
                      height: 25.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEAB308).withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
                );
              },
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
              // Celebration animation placeholder
              Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.5),
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
                '🎉 Excellent Work! 🎉',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'You understand what money can buy!',
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

class ChoiceOption {
  final String icon;
  final String label;
  bool isSelected;

  ChoiceOption({
    required this.icon,
    required this.label,
    required this.isSelected,
  });
}
