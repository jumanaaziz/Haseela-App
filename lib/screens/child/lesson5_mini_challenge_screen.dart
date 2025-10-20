import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Lesson5MiniChallengeScreen extends StatefulWidget {
  final String childName;
  final int currentLesson;
  final int totalLessons;
  final String childId;
  final VoidCallback onComplete;

  const Lesson5MiniChallengeScreen({
    super.key,
    required this.childName,
    required this.currentLesson,
    required this.totalLessons,
    required this.childId,
    required this.onComplete,
  });

  @override
  State<Lesson5MiniChallengeScreen> createState() =>
      _Lesson5MiniChallengeScreenState();
}

class SmartChoiceQuestion {
  final String scenario;
  final List<String> options;
  final List<String> optionEmojis;
  final int correctIndex;
  final String correctFeedback;
  final String incorrectFeedback;

  SmartChoiceQuestion({
    required this.scenario,
    required this.options,
    required this.optionEmojis,
    required this.correctIndex,
    required this.correctFeedback,
    required this.incorrectFeedback,
  });
}

class _Lesson5MiniChallengeScreenState extends State<Lesson5MiniChallengeScreen>
    with TickerProviderStateMixin {
  late AnimationController _haseelController;
  late AnimationController _celebrationController;
  late AnimationController _sparkleController;

  List<SmartChoiceQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _selectedAnswerIndex = -1;
  int _score = 0;
  bool _showFeedback = false;
  bool _isCompleted = false;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _initializeQuestions();
    _initializeAnimations();
  }

  void _initializeQuestions() {
    _questions = [
      SmartChoiceQuestion(
        scenario:
            "You want new headphones. One costs 60 SAR with high quality; another costs 20 SAR but breaks easily.",
        options: [
          "Buy the cheap one now",
          "Wait and save for the better one",
          "Borrow from a friend temporarily",
        ],
        optionEmojis: ["🎧", "💰", "🤝"],
        correctIndex: 1,
        correctFeedback:
            "Great choice! You thought about quality and long-term value. Better headphones will last longer and save you money!",
        incorrectFeedback:
            "Hmm, that might cost you more later. Think about what lasts longer and gives better value.",
      ),
      SmartChoiceQuestion(
        scenario:
            "You have 50 SAR. A toy costs 45 SAR, but you also need lunch money for the week.",
        options: [
          "Buy the toy immediately",
          "Save for now and buy later",
          "Ask parents for extra money",
        ],
        optionEmojis: ["🎮", "🍱", "👨‍👩‍👧‍👦"],
        correctIndex: 1,
        correctFeedback:
            "Smart thinking! Taking care of your needs first shows good priorities. You can save for the toy later!",
        incorrectFeedback:
            "Remember, needs come before wants. Lunch is more important than toys right now.",
      ),
      SmartChoiceQuestion(
        scenario:
            "Your phone case broke. You need a new one to protect your phone.",
        options: [
          "Buy a simple one for 10 SAR",
          "Get a trendy one for 40 SAR",
          "Wait until you have more money",
        ],
        optionEmojis: ["📱", "💅", "⏰"],
        correctIndex: 0,
        correctFeedback:
            "Perfect! A simple case protects your phone just as well. You saved 30 SAR for other things!",
        incorrectFeedback:
            "Think about what you really need. A simple case protects your phone just as well as an expensive one.",
      ),
      SmartChoiceQuestion(
        scenario:
            "You get Eid money (100 SAR). You want to buy something special.",
        options: [
          "Spend it all in one day",
          "Save half, spend half",
          "Save it all for something bigger",
        ],
        optionEmojis: ["🛍️", "🎁", "🏦"],
        correctIndex: 1,
        correctFeedback:
            "Excellent balance! You're enjoying your Eid money while also saving for the future. That's smart money management!",
        incorrectFeedback:
            "Think about balance. It's okay to enjoy your money, but saving some helps you reach bigger goals.",
      ),
      SmartChoiceQuestion(
        scenario: "Your friend forgot their lunch money. They look hungry.",
        options: [
          "Ignore and keep yours",
          "Share some of yours",
          "Give them all your money",
        ],
        optionEmojis: ["🍔", "🤝", "💸"],
        correctIndex: 1,
        correctFeedback:
            "Kind and smart! Sharing shows generosity while still taking care of yourself. That's the right balance!",
        incorrectFeedback:
            "Being generous is good, but remember to take care of yourself too. Sharing is better than giving everything.",
      ),
      SmartChoiceQuestion(
        scenario:
            "A game subscription is on sale for 50% off. You're not sure if you'll use it much.",
        options: [
          "Buy because it's cheap",
          "Check if you use it often before buying",
          "Ask friends what they think",
        ],
        optionEmojis: ["🤑", "🧠", "👥"],
        correctIndex: 1,
        correctFeedback:
            "Smart decision! Even if something is cheap, it's only a good deal if you'll actually use it. Great thinking!",
        incorrectFeedback:
            "A sale doesn't always mean it's a good deal. Think about whether you'll actually use it before buying.",
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
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _haseelController.dispose();
    _celebrationController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (_showFeedback) return;

    setState(() {
      _selectedAnswerIndex = index;
    });

    // Show feedback after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _showAnswerFeedback();
    });
  }

  void _showAnswerFeedback() {
    setState(() {
      _showFeedback = true;
    });

    final question = _questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswerIndex == question.correctIndex;

    if (isCorrect) {
      _score++;
      _sparkleController.forward();
    }

    // Show feedback message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text('🐇'),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                isCorrect
                    ? question.correctFeedback
                    : question.incorrectFeedback,
              ),
            ),
          ],
        ),
        backgroundColor: isCorrect
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );

    // Move to next question or complete
    Future.delayed(const Duration(seconds: 6), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = -1;
        _showFeedback = false;
      });
    } else {
      _completeChallenge();
    }
  }

  void _completeChallenge() {
    setState(() {
      _isCompleted = true;
      _showCelebration = true;
    });
    _celebrationController.forward();

    Future.delayed(const Duration(seconds: 100), () {
      widget.onComplete();
    });
  }

  void _retryChallenge() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = -1;
      _score = 0;
      _showFeedback = false;
      _isCompleted = false;
      _showCelebration = false;
    });
    _celebrationController.reset();
    _sparkleController.reset();
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
                  Color(0xFFFEF3C7), // Light yellow
                  Color(0xFFE0F2FE), // Light teal
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Floating sparkles
                  _buildFloatingSparkles(),

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
                        _buildQuestionCard(),
                        SizedBox(height: isTablet ? 40.h : 32.h),
                        _buildOptionsGrid(),
                        SizedBox(height: isTablet ? 40.h : 32.h),
                        _buildScoreIndicator(),
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
              Icon(Icons.psychology, color: Colors.white, size: 32.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Mini Challenge: Smart Decisions',
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
            'Think before you spend!',
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
                  '"Let\'s practice making smart money decisions! Think about what\'s really important before you choose."',
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

  Widget _buildQuestionCard() {
    if (_isCompleted) return const SizedBox.shrink();

    final question = _questions[_currentQuestionIndex];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'of ${_questions.length}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            question.scenario,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid() {
    if (_isCompleted) return const SizedBox.shrink();

    final question = _questions[_currentQuestionIndex];

    return Column(
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final emoji = question.optionEmojis[index];
        final isSelected = _selectedAnswerIndex == index;
        final isCorrect = index == question.correctIndex;

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          child: GestureDetector(
            onTap: () => _selectAnswer(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isCorrect ? Colors.green[50] : Colors.red[50])
                    : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected
                      ? (isCorrect
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                      : const Color(0xFFE2E8F0),
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              (isCorrect
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                                  .withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isCorrect
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                          : const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(emoji, style: TextStyle(fontSize: 24.sp)),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  if (isSelected) ...[
                    SizedBox(width: 8.w),
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 24.sp,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoreIndicator() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Smart Choices',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            '$_score/${_questions.length}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: _score >= 4
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingSparkles() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Sparkle 1
            Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              left: MediaQuery.of(context).size.width * 0.1,
              child: AnimatedBuilder(
                animation: _sparkleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _sparkleController.value,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: Colors.amber[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('✨', style: TextStyle(fontSize: 12.sp)),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Sparkle 2
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              right: MediaQuery.of(context).size.width * 0.15,
              child: AnimatedBuilder(
                animation: _sparkleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _sparkleController.value,
                    child: Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        color: Colors.amber[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('⭐', style: TextStyle(fontSize: 10.sp)),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Sparkle 3
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.3,
              left: MediaQuery.of(context).size.width * 0.2,
              child: AnimatedBuilder(
                animation: _sparkleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _sparkleController.value,
                    child: Container(
                      width: 18.w,
                      height: 18.w,
                      decoration: BoxDecoration(
                        color: Colors.amber[400],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('💫', style: TextStyle(fontSize: 11.sp)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationOverlay() {
    final isSmartSaver = _score >= 4;

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
                      Text(
                        isSmartSaver ? '🧠💰' : '🐇✨',
                        style: TextStyle(fontSize: 60.sp),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        isSmartSaver ? 'Smart Saver!' : 'Keep Practicing!',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        isSmartSaver
                            ? 'Haseel thinks you\'re a Smart Saver! You made $_score out of ${_questions.length} smart choices!'
                            : 'Every smart choice counts. You made $_score out of ${_questions.length} smart choices!',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _retryChallenge,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 12.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'Try Again',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: widget.onComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 12.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
