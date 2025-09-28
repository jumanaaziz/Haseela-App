import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'splash/splash_screen.dart';
import 'splash/launch_screen_old.dart';
import 'parent/parent_profile_screen.dart';
import 'parent/task_management_screen.dart';

/// Handles authentication state and navigation after login
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('AuthWrapper: Connection state: ${snapshot.connectionState}');
        print('AuthWrapper: Has data: ${snapshot.hasData}');
        print('AuthWrapper: Has error: ${snapshot.hasError}');

        // 1️⃣ Still checking → Splash screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // 2️⃣ If error → Launch screen
        if (snapshot.hasError) {
          return const LaunchScreenOld();
        }

        // 3️⃣ If user is authenticated → navigate to ParentProfile first
        if (snapshot.hasData && snapshot.data != null) {
          print(
            'AuthWrapper: User authenticated, navigating to ParentProfileScreen',
          );
          return const ParentProfileScreen();
        }

        // 4️⃣ If not authenticated → Launch screen (login/signup)
        print('AuthWrapper: No user, showing LaunchScreen');
        return const LaunchScreenOld();
      },
    );
  }
}
