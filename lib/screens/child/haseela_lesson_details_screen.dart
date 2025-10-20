import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'haseela_lessons_overview_screen.dart';
import 'lesson1_mini_challenge_screen.dart';
import 'lesson2_mini_challenge_screen.dart';
import 'lesson3_mini_challenge_screen.dart';
import 'lesson4_mini_challenge_screen.dart';
import 'lesson5_mini_challenge_screen.dart';

class HaseelaLessonDetailsScreen extends StatefulWidget {
  final LessonLevel lesson;
  final String childName;
  final String childId;
  final String? parentId; // Make parentId optional for backward compatibility

  const HaseelaLessonDetailsScreen({
    super.key,
    required this.lesson,
    required this.childName,
    required this.childId,
    this.parentId,
  });

  @override
  State<HaseelaLessonDetailsScreen> createState() =>
      _HaseelaLessonDetailsScreenState();
}

class _HaseelaLessonDetailsScreenState extends State<HaseelaLessonDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _floatingController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _floatingAnimation;

  bool isLessonCompleted = false;
  bool showCelebration = false;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _floatingAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _navigateToMiniChallenge() {
    Widget challengeScreen;

    switch (widget.lesson.id) {
      case 1:
        challengeScreen = Lesson1MiniChallengeScreen(
          childName: widget.childName,
          currentLesson: widget.lesson.id,
          totalLessons: 5,
          childId: widget.childId,
          onComplete: () {
            _updateChildLevelAndReturnToOverview();
          },
        );
        break;
      case 2:
        challengeScreen = Lesson2MiniChallengeScreen(
          childName: widget.childName,
          currentLesson: widget.lesson.id,
          totalLessons: 5,
          childId: widget.childId,
          onComplete: () {
            _updateChildLevelAndReturnToOverview();
          },
        );
        break;
      case 3:
        challengeScreen = Lesson3MiniChallengeScreen(
          childName: widget.childName,
          currentLesson: widget.lesson.id,
          totalLessons: 5,
          childId: widget.childId,
          onComplete: () {
            _updateChildLevelAndReturnToOverview();
          },
        );
        break;
      case 4:
        challengeScreen = Lesson4MiniChallengeScreen(
          childName: widget.childName,
          currentLesson: widget.lesson.id,
          totalLessons: 5,
          childId: widget.childId,
          onComplete: () {
            _updateChildLevelAndReturnToOverview();
          },
        );
        break;
      case 5:
        challengeScreen = Lesson5MiniChallengeScreen(
          childName: widget.childName,
          currentLesson: widget.lesson.id,
          totalLessons: 5,
          childId: widget.childId,
          onComplete: () {
            _updateChildLevelAndReturnToOverview();
          },
        );
        break;
      default:
        Navigator.pop(context);
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => challengeScreen),
    );
  }

  void _updateChildLevelAndReturnToOverview() async {
    try {
      await FirebaseFirestore.instance
          .collection('Children')
          .doc(widget.childId)
          .update({'level': FieldValue.increment(1)});

      // Show celebration
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Great job! Next lesson unlocked! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate directly back to lessons overview (bypassing lesson details)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HaseelaLessonsOverviewScreen(
            childName: widget.childName,
            childId: widget.childId,
            parentId: widget.parentId, // Pass parentId
          ),
        ),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      print('Error updating child level: $e');
      // Still navigate back even if update fails
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HaseelaLessonsOverviewScreen(
            childName: widget.childName,
            childId: widget.childId,
            parentId: widget.parentId, // Pass parentId
          ),
        ),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
              const Color(0xFFE2E8F0).withOpacity(0.3),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 20.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Tracker
                      _buildProgressTracker(),
                      SizedBox(height: 24.h),

                      // Lesson Illustration
                      _buildLessonIllustration(),
                      SizedBox(height: 24.h),

                      // Lesson Content
                      _buildLessonContent(),
                      SizedBox(height: 32.h),

                      // Completion Button
                      _buildCompletionButton(),
                      SizedBox(height: 24.h),

                      // Floating Elements
                      _buildFloatingElements(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.lesson.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.lesson.gradient[0].withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level ${widget.lesson.id} - ${widget.lesson.title}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Learn with Haseel! 🐇',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(widget.lesson.icon, style: TextStyle(fontSize: 24.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final isCompleted = index < widget.lesson.id;
          final isCurrent = index == widget.lesson.id - 1;

          return Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : isCurrent
                  ? widget.lesson.gradient[0]
                  : const Color(0xFFE2E8F0),
              border: isCurrent
                  ? Border.all(color: widget.lesson.gradient[0], width: 2)
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLessonIllustration() {
    return Container(
      width: double.infinity,
      height: 200.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.lesson.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: widget.lesson.gradient[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background elements
          Positioned(
            top: 20.h,
            right: 20.w,
            child: AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatingAnimation.value),
                  child: Text('🪙', style: TextStyle(fontSize: 32.sp)),
                );
              },
            ),
          ),
          Positioned(
            top: 40.h,
            left: 20.w,
            child: AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_floatingAnimation.value),
                  child: Text('💵', style: TextStyle(fontSize: 28.sp)),
                );
              },
            ),
          ),
          Positioned(
            bottom: 20.h,
            right: 40.w,
            child: AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatingAnimation.value * 0.5),
                  child: Text('⭐', style: TextStyle(fontSize: 24.sp)),
                );
              },
            ),
          ),
          // Main illustration
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🐇', style: TextStyle(fontSize: 60.sp)),
                SizedBox(height: 8.h),
                Text(
                  'Haseel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Your Money Guide',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lesson Story',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 16.h),
          ..._getLessonStoryContent(),
        ],
      ),
    );
  }

  List<Widget> _getLessonStoryContent() {
    switch (widget.lesson.id) {
      case 1:
        return _getLevel1Content();
      case 2:
        return _getLevel2Content();
      case 3:
        return _getLevel3Content();
      case 4:
        return _getLevel4Content();
      case 5:
        return _getLevel5Content();
      default:
        return _getLevel1Content();
    }
  }

  List<Widget> _getLevel1Content() {
    return [
      _buildStoryBubble(
        'Haseel: "Hey, I\'m Haseel — let\'s explore how money actually works."',
        true,
        '🐇',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'You: "So basically, Riyals are what we use to exchange for things — like food, clothes, or even digital stuff online?"',
        false,
        '👦',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'Haseel: "Exactly. Riyals make it simple to trade — you earn them, save them, and spend them wisely. That\'s how people build good money habits."',
        true,
        '🐇',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'You: "I use them every week at the school canteen, and sometimes I save part of my Eidiya."',
        false,
        '👦',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'Haseel: "Smart observation! You\'re already thinking about both spending and saving. That\'s the foundation of good money management."',
        true,
        '🐇',
      ),
    ];
  }

  List<Widget> _getLevel2Content() {
    return [
      _buildStoryBubble(
        'Haseel: "Welcome back! You\'ve learned what Riyals mean — now let\'s talk about how you earn them."',
        true,
        '🐇',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'You: "I get a small allowance every week. But sometimes my parents give me extra if I help my younger brother or wash the car."',
        false,
        '👦',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'Haseel: "Exactly! Earning Riyals usually means giving time, effort, or skill to do something useful. It\'s not just about chores — it\'s about adding value."',
        true,
        '🐇',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'You: "So like when I help my class with a project or design a cool slide deck — that\'s a skill too?"',
        false,
        '👦',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'Haseel: "You got it! Whether it\'s designing, tutoring, or helping out at home, you\'re learning that every Riyal comes from effort. People work, create, and solve problems — and they get paid for the value they give."',
        true,
        '🐇',
      ),
    ];
  }

  List<Widget> _getLevel3Content() {
    return [
      _buildStoryBubble(
        'Haseel: "Now let\'s talk about the big question: save or spend? This is where smart money decisions really matter."',
        true,
        '🐇',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'You: "I always want to buy something right away, but then I regret it later when I can\'t afford something I really want."',
        false,
        '👦',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'Haseel: "That\'s exactly the trade-off we\'re talking about. Instant reward vs future reward. It\'s about delayed gratification — waiting for something better."',
        true,
        '🐇',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'You: "So like saving 100 Riyals over a few weeks for AirPods instead of spending 20 Riyals every week on snacks?"',
        false,
        '👦',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'Haseel: "Perfect example! You\'re thinking like a real saver. The key is finding your balance — some spending for fun, some saving for goals."',
        true,
        '🐇',
      ),
    ];
  }

  List<Widget> _getLevel4Content() {
    return [
      _buildStoryBubble(
        'Haseel: "Let\'s talk about setting goals and planning ahead. This is where you turn dreams into reality."',
        true,
        '🐇',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'You: "I want to save for a PlayStation card, but I keep spending my allowance on other things."',
        false,
        '👦',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'Haseel: "That\'s where planning comes in. Set a specific goal — like 200 Riyals for that PlayStation card — and break it down. How much do you need to save each week?"',
        true,
        '🐇',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'You: "If I save 50 Riyals per week, I\'d have it in 4 weeks. But that means no snacks or small purchases."',
        false,
        '👦',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'Haseel: "Smart thinking! You\'re weighing the trade-offs. Maybe save 40 Riyals and keep 10 for small treats? The key is making it sustainable."',
        true,
        '🐇',
      ),
    ];
  }

  List<Widget> _getLevel5Content() {
    return [
      _buildStoryBubble(
        'Haseel: "Final lesson: smart spending and generosity. This is where you put it all together."',
        true,
        '🐇',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'You: "I want to buy new sneakers, but I also want to give some money to charity. How do I decide?"',
        false,
        '👦',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'Haseel: "Great question! Think about priorities: needs vs wants vs giving. The sneakers are a want, charity is generosity. Maybe set aside 10% of your money for Sadaqah?"',
        true,
        '🐇',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'You: "So like if I have 100 Riyals, save 60 for sneakers, spend 30 on other things, and give 10 to charity?"',
        false,
        '👦',
      ),
      SizedBox(height: 12.h),
      _buildStoryBubble(
        'Haseel: "Exactly! You\'re thinking like a responsible money manager. Balance your goals, enjoy some spending, and remember to help others. That\'s financial wisdom."',
        true,
        '🐇',
      ),
    ];
  }

  Widget _buildStoryBubble(String text, bool isHaseel, String emoji) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHaseel
              ? [
                  const Color(0xFF667EEA).withOpacity(0.1),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ]
              : [
                  const Color(0xFF10B981).withOpacity(0.1),
                  const Color(0xFF059669).withOpacity(0.1),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isHaseel
              ? const Color(0xFF667EEA).withOpacity(0.3)
              : const Color(0xFF10B981).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 24.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionButton() {
    if (isLessonCompleted) {
      return AnimatedBuilder(
        animation: _celebrationAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _celebrationAnimation.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '🎉 Congratulations! 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'You completed this lesson!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      _navigateToMiniChallenge();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF10B981),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Continue Learning',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: widget.lesson.gradient),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: widget.lesson.gradient[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            setState(() {
              isLessonCompleted = true;
              showCelebration = true;
            });
            _celebrationController.forward();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'I\'m Done!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingElements() {
    if (!showCelebration) return SizedBox(height: 20.h);

    return SizedBox(
      height: 100.h,
      child: Stack(
        children: [
          // Celebration elements
          ...List.generate(8, (index) {
            final angle = (index * 45) * (3.14159 / 180);
            final radius = 40.w;
            final x = radius * cos(angle);
            final y = radius * sin(angle);

            return Positioned(
              left: 200.w + x,
              top: 50.h + y,
              child: AnimatedBuilder(
                animation: _celebrationAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _celebrationAnimation.value,
                    child: Text(
                      index % 2 == 0 ? '⭐' : '🎉',
                      style: TextStyle(fontSize: 20.sp),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Helper function for trigonometry
double cos(double radians) {
  return radians == 0
      ? 1.0
      : radians == 3.14159 / 2
      ? 0.0
      : radians == 3.14159
      ? -1.0
      : radians == 3 * 3.14159 / 2
      ? 0.0
      : radians == 2 * 3.14159
      ? 1.0
      : radians < 3.14159 / 2
      ? 1.0 - radians * radians / 2
      : radians < 3.14159
      ? -(radians - 3.14159 / 2)
      : radians < 3 * 3.14159 / 2
      ? -(1.0 - (radians - 3.14159) * (radians - 3.14159) / 2)
      : radians - 3 * 3.14159 / 2;
}

double sin(double radians) {
  return cos(radians - 3.14159 / 2);
}
