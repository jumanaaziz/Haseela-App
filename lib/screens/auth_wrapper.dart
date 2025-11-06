import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'splash/splash_screen.dart';
import 'splash/launch_screen_old.dart';
import 'parent/parent_profile_screen.dart';
import 'child_main_wrapper.dart';

// ✅ Simple Session Service to store role + IDs globally
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  String? role;
  String? parentId;
  String? childId;

  void clear() {
    role = null;
    parentId = null;
    childId = null;
  }
}

final session = SessionService();

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

        // 🕓 1️⃣ Still waiting for Firebase to settle
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // ⚠️ 2️⃣ If error
        if (snapshot.hasError) {
          session.clear();
          return const LaunchScreenOld();
        }

        // 🧩 3️⃣ Handle user null carefully (transient null protection)
        final user = snapshot.data;
        if (user == null) {
          print(
            'AuthWrapper: ⚠️ No authenticated user yet (might be transient)',
          );
          // Don’t immediately clear session; wait a brief moment
          return const SplashScreen();
        }

        print('AuthWrapper: ✅ Authenticated as ${user.uid} — checking role...');

        // 🔍 4️⃣ Fetch role document
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            if (userSnapshot.hasError) {
              print(
                'AuthWrapper: ❌ Error fetching user document: ${userSnapshot.error}',
              );
              return const LaunchScreenOld();
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              print(
                'AuthWrapper: ⚠️ No user document found for UID: ${user.uid}',
              );
              session.clear();
              return const LaunchScreenOld();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            final role = data['role'] as String?;
            print('AuthWrapper: Role = $role');

            if (role == 'parent') {
              session.role = 'parent';
              session.parentId = user.uid;
              session.childId = null;
              return const ParentProfileScreen();
            } else if (role == 'child') {
              final parentId = data['parentId'];
              final childId = data['childId'];

              session.role = 'child';
              session.parentId = parentId;
              session.childId = childId;
              return ChildMainWrapper(parentId: parentId, childId: childId);
            } else {
              print('AuthWrapper: Unknown role value "$role"');
              session.clear();
              return const LaunchScreenOld();
            }
          },
        );
      },
    );
  }
}
