import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Lesson4MiniChallengeScreen extends StatefulWidget {
  final String childName;
  final int currentLesson;
  final int totalLessons;
  final String childId;
  final VoidCallback onComplete;

  const Lesson4MiniChallengeScreen({
    super.key,
    required this.childName,
    required this.currentLesson,
    required this.totalLessons,
    required this.childId,
    required this.onComplete,
  });

  @override
  State<Lesson4MiniChallengeScreen> createState() =>
      _Lesson4MiniChallengeScreenState();
}

class _Lesson4MiniChallengeScreenState extends State<Lesson4MiniChallengeScreen>
    with TickerProviderStateMixin {
  late AnimationController _haseelController;
  late AnimationController _heartController;
  late AnimationController _celebrationController;

  List<ChoiceOption> _options = [
    ChoiceOption(
      icon: Icons.sports_esports,
      label: 'PlayStation card (200 Riyals)',
      description: 'Short-term goal - achievable in 1-2 months',
      isCorrect: true,
      goalType: 'short',
    ),
    ChoiceOption(
      icon: Icons.school,
      label: 'College fund (5000 Riyals)',
      description: 'Long-term goal - takes years to achieve',
      isCorrect: true,
      goalType: 'long',
    ),
    ChoiceOption(
      icon: Icons.phone_android,
      label: 'New smartphone (800 Riyals)',
      description: 'Medium-term goal - achievable in 3-6 months',
      isCorrect: true,
      goalType: 'medium',
    ),
    ChoiceOption(
      icon: Icons.shopping_cart,
      label: 'Buy everything I want',
      description: 'Spending all money immediately',
      isCorrect: false,
      goalType: 'impulse',
    ),
    ChoiceOption(
      icon: Icons.money_off,
      label: 'Never spend anything',
      description: 'Saving everything forever',
      isCorrect: false,
      goalType: 'extreme',
    ),
  ];

  List<ChoiceOption> _selectedOptions = [];
  bool _isCompleted = false;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _haseelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _heartController = AnimationController(
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
    _heartController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _toggleOption(ChoiceOption option) {
    setState(() {
      if (_selectedOptions.contains(option)) {
        // Remove if already selected
        _selectedOptions.remove(option);
      } else if (_selectedOptions.length < 3) {
        // Add only if less than 3 are selected
        _selectedOptions.add(option);
      } else {
        // Show message when trying to select more than 3
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text('🐇'),
                SizedBox(width: 8.w),
                Text('You can only select 3 goals maximum!'),
              ],
            ),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _checkAnswers() {
    if (_selectedOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text('🐇'),
              SizedBox(width: 8.w),
              Text('Please select at least one goal!'),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Count correct and incorrect selections
    int correctCount = _selectedOptions
        .where((option) => option.isCorrect)
        .length;
    int incorrectCount = _selectedOptions
        .where((option) => !option.isCorrect)
        .length;
    int totalCorrect = _options.where((option) => option.isCorrect).length;

    // Check if all correct goals are selected and no incorrect ones
    bool allCorrectSelected = correctCount == totalCorrect;
    bool noIncorrectSelected = incorrectCount == 0;

    if (allCorrectSelected && noIncorrectSelected) {
      setState(() {
        _isCompleted = true;
        _showCelebration = true;
      });
      _celebrationController.forward();

      // Show success message with specific feedback
      String feedback = _getSuccessFeedback(correctCount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text('🐇'),
              SizedBox(width: 8.w),
              Expanded(child: Text(feedback)),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        widget.onComplete();
      });
    } else {
      // Provide specific feedback based on selections
      String feedback = _getFeedbackMessage(
        correctCount,
        incorrectCount,
        totalCorrect,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text('🐇'),
              SizedBox(width: 8.w),
              Expanded(child: Text(feedback)),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getSuccessFeedback(int correctCount) {
    switch (correctCount) {
      case 3:
        return 'Perfect! You\'ve selected all realistic goals — that\'s excellent planning! 🎯';
      case 2:
        return 'Great! You\'re thinking about different timeframes for your goals! 📅';
      case 1:
        return 'Good start! Try selecting goals for different time periods! ⏰';
      default:
        return 'Nice work! You\'re learning about goal setting! 🎉';
    }
  }

  String _getFeedbackMessage(
    int correctCount,
    int incorrectCount,
    int totalCorrect,
  ) {
    if (incorrectCount > 0) {
      return 'Some of your choices aren\'t realistic goals. Try selecting items you can actually work towards! 🤔';
    } else if (correctCount < totalCorrect) {
      return 'You\'re on the right track! Try selecting goals for different time periods (short, medium, long-term). 📈';
    } else {
      return 'Think about which goals are realistic and achievable! 💭';
    }
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
                  Color(0xFFFCE7F3), // Light pink
                  Color(0xFFF0FDF4), // Light green
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Floating hearts and coins
                  _buildFloatingElements(),

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
                        _buildChoiceArea(),
                        SizedBox(height: isTablet ? 40.h : 32.h),
                        _buildProgressIndicator(),
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
                        colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
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
          colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
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
              Icon(Icons.flag, color: Colors.white, size: 32.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Mini Challenge: Goal Setting & Planning',
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
            'Set your financial goals!',
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
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.3),
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
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '"You want to set some financial goals. Which of these are realistic goals you could work towards? Select up to 3 goals!"',
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

  Widget _buildChoiceArea() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Kind Acts:',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20.h),
          ...List.generate(_options.length, (index) {
            final option = _options[index];
            final isSelected = _selectedOptions.contains(option);
            final isLimitReached = _selectedOptions.length >= 3 && !isSelected;

            return Container(
              margin: EdgeInsets.only(bottom: 16.h),
              child: GestureDetector(
                onTap: () => _toggleOption(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (option.isCorrect ? Colors.green[50] : Colors.red[50])
                        : isLimitReached
                        ? Colors.grey[100]
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected
                          ? (option.isCorrect
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                          : isLimitReached
                          ? Colors.grey[300]!
                          : Colors.white.withOpacity(0.3),
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  (option.isCorrect
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444))
                                      .withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (option.isCorrect
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                              : isLimitReached
                              ? Colors.grey[300]
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          option.icon,
                          color: isSelected
                              ? Colors.white
                              : isLimitReached
                              ? Colors.grey[500]
                              : Colors.white.withOpacity(0.8),
                          size: 32.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              option.description,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF475569)
                                    : Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
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
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    int incorrectSelected = _selectedOptions
        .where((option) => !option.isCorrect)
        .length;

    return Container(
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Answer Progress',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                '${_selectedOptions.length}/3',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: _selectedOptions.length == 3
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          LinearProgressIndicator(
            value: _selectedOptions.length / 3,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _selectedOptions.length == 3
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
            ),
            minHeight: 8.h,
          ),
          if (incorrectSelected > 0) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 16.sp),
                SizedBox(width: 8.w),
                Text(
                  '$incorrectSelected incorrect choice${incorrectSelected > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
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
          _isCompleted ? Icons.check_circle : Icons.favorite,
          size: 24.sp,
        ),
        label: Text(
          _isCompleted ? 'Completed!' : 'Check My Choices',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCompleted ? Colors.grey : const Color(0xFFF59E0B),
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

  Widget _buildFloatingElements() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Floating heart 1
            AnimatedBuilder(
              animation: _heartController,
              builder: (context, child) {
                return Positioned(
                  top:
                      MediaQuery.of(context).size.height * 0.1 +
                      (30 * _heartController.value),
                  left:
                      MediaQuery.of(context).size.width * 0.1 +
                      (20 * _heartController.value),
                  child: Opacity(
                    opacity: 0.7,
                    child: Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Floating coin
            AnimatedBuilder(
              animation: _heartController,
              builder: (context, child) {
                return Positioned(
                  top:
                      MediaQuery.of(context).size.height * 0.3 +
                      (25 * (1 - _heartController.value)),
                  right:
                      MediaQuery.of(context).size.width * 0.15 +
                      (15 * (1 - _heartController.value)),
                  child: Opacity(
                    opacity: 0.6,
                    child: Container(
                      width: 25.w,
                      height: 25.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.5),
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
            // Floating heart 2
            AnimatedBuilder(
              animation: _heartController,
              builder: (context, child) {
                return Positioned(
                  bottom:
                      MediaQuery.of(context).size.height * 0.2 +
                      (20 * _heartController.value),
                  left:
                      MediaQuery.of(context).size.width * 0.2 +
                      (25 * _heartController.value),
                  child: Opacity(
                    opacity: 0.5,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 12.sp,
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
              Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.5),
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
                '🎉 That\'s the Spirit! 🎉',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Giving makes the world brighter!',
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
  final IconData icon;
  final String label;
  final String description;
  final bool isCorrect;
  final String goalType;

  ChoiceOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isCorrect,
    required this.goalType,
  });
}
