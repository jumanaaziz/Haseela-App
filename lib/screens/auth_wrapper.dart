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

  /// Search for child user in Parents/{parentId}/Children/{childId}
  /// Returns [parentId, childId] if found, empty list otherwise
  Future<List<String>> _findChildInParents(String uid) async {
    try {
      // Get all parent documents
      final parentsSnapshot = await FirebaseFirestore.instance
          .collection('Parents')
          .get();

      // Search through each parent's children
      for (var parentDoc in parentsSnapshot.docs) {
        final parentId = parentDoc.id;
        final childDoc = await FirebaseFirestore.instance
            .collection('Parents')
            .doc(parentId)
            .collection('Children')
            .doc(uid)
            .get();

        if (childDoc.exists) {
          print('AuthWrapper: Found child $uid under parent $parentId');
          return [parentId, uid];
        }
      }

      print('AuthWrapper: Child $uid not found in any parent\'s children');
      return [];
    } catch (e) {
      print('AuthWrapper: Error searching for child: $e');
      return [];
    }
  }

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

        // 🔍 4️⃣ Try to find user in Users collection first (for parents/new format)
        // If not found, search for child in Parents/{parentId}/Children/{childId}
        return FutureBuilder<DocumentSnapshot?>(
          future: FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get()
              .then((doc) => doc.exists ? doc : null)
              .catchError((_) => null),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            // If found in Users collection, use it
            if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>;
              final role = data['role'] as String?;
              print('AuthWrapper: Found in Users collection, Role = $role');

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
                print('AuthWrapper: Child found in Users - parentId: $parentId, childId: $childId');
                return ChildMainWrapper(parentId: parentId, childId: childId);
              }
            }

            // If not in Users, search for child in Parents collections
            print('AuthWrapper: Not in Users collection, searching for child in Parents...');
            return FutureBuilder<List<String>>(
              future: _findChildInParents(user.uid),
              builder: (context, childSearchSnapshot) {
                if (childSearchSnapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }

                if (childSearchSnapshot.hasData && childSearchSnapshot.data != null) {
                  final result = childSearchSnapshot.data!;
                  if (result.length == 2) {
                    final parentId = result[0];
                    final childId = result[1];
                    print('AuthWrapper: ✅ Child found! parentId: $parentId, childId: $childId');
                    session.role = 'child';
                    session.parentId = parentId;
                    session.childId = childId;
                    return ChildMainWrapper(parentId: parentId, childId: childId);
                  }
                }

                // Not found anywhere
                print('AuthWrapper: ⚠️ User not found in Users or as child in Parents');
                session.clear();
                return const LaunchScreenOld();
              },
            );
          },
        );
      },
    );
  }
}
