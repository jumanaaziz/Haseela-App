import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../auth_background.dart';
import '../auth/parent_login_screen.dart';
import '../auth/signup_screen.dart';
import '../auth/child_login_screen.dart';

class LaunchScreenOld extends StatelessWidget {
  const LaunchScreenOld({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: 500.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            /// 🟣 Logo
                            Image.asset(
                              'assets/images/logo.png',
                              width: 220.w,
                              height: 220.h,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: 60.h),

                            /// 🟣 Title
                            Text(
                              'Welcome to Haseela',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              'Your journey starts here',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 60.h),

                            /// 🟠 Log in as Parent
                            SizedBox(
                              width: double.infinity,
                              height: 50.h,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ParentLoginScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8D61B4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  'Log in as Parent',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold, // ✅ Bold
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),

                            /// 🟡 Log in as Child
                            SizedBox(
                              width: double.infinity,
                              height: 50.h,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ChildLoginScreen(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: const Color(0xFF8D61B4),
                                    width: 2.w,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                ),
                                child: Text(
                                  'Log in as Child',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold, // ✅ Bold
                                    color: const Color(0xFF8D61B4),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),

                            /// 🟢 Sign Up (old version)
                            SizedBox(
                              width: double.infinity,
                              height: 50.h,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignUpScreen(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: const Color(0xFF8D61B4),
                                    width: 2.w,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF8D61B4),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
